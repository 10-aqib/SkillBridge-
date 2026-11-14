import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/map/map_config.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Address search and reverse geocoding (Navigation phase 3), behind an
/// interface so the provider can be replaced without touching screens.
///
/// The default is any Nominatim-compatible server ([GeocodingConfig]).
/// Searches run only when the user submits (never as autocomplete), at most
/// one request a second, and results are cached; that is what the public
/// Nominatim policy requires. With [GeocodingProvider.none], screens let
/// people pick on the map instead.

class GeocodedPlace {
  const GeocodedPlace({required this.point, required this.label, this.name = '', this.city = ''});
  final LatLng point;

  /// Full address line, as the provider formats it.
  final String label;

  /// Short name (first part of the address), for lists.
  final String name;

  /// Town or city, in English, or '' when the provider gives none.
  final String city;
}

enum GeocodingFailure {
  /// No connection or the server didn't answer.
  network,

  /// The server refused (rate limited, blocked) or answered nonsense.
  unavailable,
}

class GeocodingException implements Exception {
  const GeocodingException(this.failure, [this.detail = '']);
  final GeocodingFailure failure;
  final String detail;

  @override
  String toString() => 'GeocodingException(${failure.name}${detail.isEmpty ? '' : ': $detail'})';
}

abstract class GeocodingService {
  /// Whether [search] can be offered at all.
  bool get searchEnabled;

  /// Places matching [query] (empty when none match). Throws
  /// [GeocodingException] when the service can't be reached.
  Future<List<GeocodedPlace>> search(String query);

  /// The address at [point], or null when unknown or unavailable. Never
  /// throws: a missing address must not block choosing a place.
  Future<GeocodedPlace?> reverse(LatLng point);

  void dispose() {}
}

/// No geocoding: pick on the map only.
class NoGeocodingService implements GeocodingService {
  const NoGeocodingService();

  @override
  bool get searchEnabled => false;

  @override
  Future<List<GeocodedPlace>> search(String query) async => const [];

  @override
  Future<GeocodedPlace?> reverse(LatLng point) async => null;

  @override
  void dispose() {}
}

class NominatimGeocodingService implements GeocodingService {
  NominatimGeocodingService(this.config, {http.Client? client, this.minGap = const Duration(seconds: 1), DateTime Function()? clock})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _clock = clock ?? DateTime.now;

  final GeocodingConfig config;
  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _clock;

  /// Shortest time between two requests to the server.
  final Duration minGap;

  static const _timeout = Duration(seconds: 10);
  static const _cacheSize = 60;

  final _cache = <String, Object>{};
  Future<void> _queue = Future.value();
  DateTime? _lastRequest;

  @override
  bool get searchEnabled => config.searchEnabled;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        // Browsers send their own User-Agent and a Referer; apps identify
        // themselves as the policy requires.
        if (!kIsWeb) 'User-Agent': 'SkillBridge/1.0 ($appUserAgentPackage)',
      };

  @override
  Future<List<GeocodedPlace>> search(String query) async {
    final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!searchEnabled || q.length < 3) return const [];
    final key = 's:${q.toLowerCase()}';
    final cached = _cache[key];
    if (cached is List<GeocodedPlace>) return cached;
    final uri = Uri.parse('${config.baseUrl}/search').replace(queryParameters: {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
      if (config.countryCodes.isNotEmpty) 'countrycodes': config.countryCodes,
      // English names, to match the app's city list.
      'accept-language': 'en',
    });
    final body = await _get(uri);
    if (body is! List) throw const GeocodingException(GeocodingFailure.unavailable, 'not a list');
    final places = body.whereType<Map<String, dynamic>>().map(parsePlace).whereType<GeocodedPlace>().toList();
    _remember(key, places);
    return places;
  }

  @override
  Future<GeocodedPlace?> reverse(LatLng point) async {
    if (!searchEnabled) return null;
    // About 1 m: the same spot isn't asked twice.
    final key = 'r:${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    final cached = _cache[key];
    if (cached is GeocodedPlace) return cached;
    final uri = Uri.parse('${config.baseUrl}/reverse').replace(queryParameters: {
      'lat': point.latitude.toStringAsFixed(6),
      'lon': point.longitude.toStringAsFixed(6),
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
      'accept-language': 'en',
    });
    try {
      final body = await _get(uri);
      if (body is! Map<String, dynamic> || body.containsKey('error')) return null;
      final place = parsePlace(body);
      if (place != null) _remember(key, place);
      return place;
    } on GeocodingException catch (e) {
      Logger.w('[Geocoding] reverse failed: $e');
      return null;
    }
  }

  /// One request at a time, at least [minGap] apart.
  Future<Object?> _get(Uri uri) {
    final done = Completer<Object?>();
    _queue = _queue.then((_) async {
      final last = _lastRequest;
      if (last != null) {
        final wait = minGap - _clock().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequest = _clock();
      try {
        final res = await _client.get(uri, headers: _headers).timeout(_timeout);
        if (res.statusCode != 200) {
          throw GeocodingException(GeocodingFailure.unavailable, 'HTTP ${res.statusCode}');
        }
        done.complete(jsonDecode(utf8.decode(res.bodyBytes)));
      } on GeocodingException catch (e) {
        done.completeError(e);
      } on FormatException {
        done.completeError(const GeocodingException(GeocodingFailure.unavailable, 'bad JSON'));
      } catch (e) {
        // Socket, TLS, timeout, client errors.
        done.completeError(GeocodingException(GeocodingFailure.network, e.runtimeType.toString()));
      }
    });
    return done.future;
  }

  void _remember(String key, Object value) {
    _cache.remove(key);
    _cache[key] = value;
    while (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// One Nominatim result, or null when it has no usable position.
  @visibleForTesting
  static GeocodedPlace? parsePlace(Map<String, dynamic> d) {
    final lat = double.tryParse('${d['lat']}');
    final lon = double.tryParse('${d['lon']}');
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) return null;
    final label = (d['display_name'] as String?)?.trim() ?? '';
    final address = d['address'] is Map ? (d['address'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = address[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    final name = (d['name'] as String?)?.trim().isNotEmpty == true
        ? (d['name'] as String).trim()
        : (label.contains(',') ? label.substring(0, label.indexOf(',')).trim() : label);
    return GeocodedPlace(
      point: LatLng(lat, lon),
      label: label,
      name: name,
      city: pick(const ['city', 'town', 'municipality', 'village', 'county', 'state_district']),
    );
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final config = ref.watch(geocodingConfigProvider);
  final GeocodingService service =
      config.searchEnabled ? NominatimGeocodingService(config) : const NoGeocodingService();
  ref.onDispose(service.dispose);
  return service;
});

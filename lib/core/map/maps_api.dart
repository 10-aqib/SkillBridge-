import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Road routes, place search and addresses from Google Maps Platform,
/// through SkillBridge's callable functions (Phase G3). The Google server
/// key stays in Secret Manager; the app only ever talks to the functions.
///
/// Until the functions are deployed (they need the Blaze plan), every call
/// fails with [MapsApiFailure.notAvailable] and the screens fall back to
/// what they did before: straight-line distance, coordinates as the address,
/// no search box.

/// A road route: length, time without live traffic, and its line.
class RouteSummary {
  const RouteSummary({required this.distanceMeters, required this.durationSeconds, required this.points});
  final int distanceMeters;
  final int durationSeconds;
  final List<GeoCoord> points;
}

/// A place from search or reverse geocoding.
class MapPlace {
  const MapPlace({required this.point, required this.label, this.name = '', this.city = ''});
  final GeoCoord point;

  /// Full address line.
  final String label;

  /// Place name (search results), or ''.
  final String name;

  /// Town or city in English, or ''.
  final String city;
}

enum MapsApiFailure {
  /// Functions not deployed or the server key isn't set up.
  notAvailable,

  /// No connection.
  offline,

  /// No road route between the points.
  noRoute,

  /// Hourly limit reached, or Google is busy.
  busy,

  /// Input refused (e.g. places too far apart).
  invalid,

  /// Anything else; try again later.
  failed,
}

class MapsApiException implements Exception {
  const MapsApiException(this.failure);
  final MapsApiFailure failure;
  @override
  String toString() => 'MapsApiException($failure)';
}

abstract class MapsApi {
  Future<RouteSummary> route(GeoCoord origin, GeoCoord destination);
  Future<List<MapPlace>> search(String query, {GeoCoord? near});
  Future<MapPlace?> reverse(GeoCoord point);

  /// False once the server said the feature isn't set up; screens then hide
  /// search and stop asking for routes for the rest of the session.
  bool get available;
}

/// Decodes a Google encoded polyline (precision 5).
List<GeoCoord> decodePolyline(String encoded) {
  final points = <GeoCoord>[];
  var index = 0, lat = 0, lng = 0;
  int next() {
    var result = 0, shift = 0, b = 0;
    do {
      if (index >= encoded.length) throw const FormatException('truncated polyline');
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.add(GeoCoord(lat / 1e5, lng / 1e5));
  }
  return points;
}

class FunctionsMapsApi implements MapsApi {
  FunctionsMapsApi(this._functions, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Read lazily: without a Firebase app (tests, misconfigured builds) the
  /// features are simply not available.
  final FirebaseFunctions Function() _functions;
  final DateTime Function() _clock;
  bool _available = true;

  // Small client caches so screens that rebuild don't re-ask.
  final _routes = <String, ({DateTime at, RouteSummary value})>{};
  final _addresses = <String, ({DateTime at, MapPlace? value})>{};

  @override
  bool get available => _available;

  static String _k(GeoCoord p, int dp) => '${p.latitude.toStringAsFixed(dp)},${p.longitude.toStringAsFixed(dp)}';
  static Map<String, double> _ll(GeoCoord p) => {'lat': p.latitude, 'lng': p.longitude};

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    if (!_available) throw const MapsApiException(MapsApiFailure.notAvailable);
    final FirebaseFunctions functions;
    try {
      functions = _functions();
    } catch (_) {
      _available = false;
      throw const MapsApiException(MapsApiFailure.notAvailable);
    }
    try {
      final r = await functions.httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 20))).call<Object?>(data);
      final v = r.data;
      if (v is Map) return Map<String, dynamic>.from(v);
      throw const MapsApiException(MapsApiFailure.failed);
    } on FirebaseFunctionsException catch (e) {
      final failure = switch (e.code) {
        'not-found' when name == 'computeRoute' && (e.message ?? '').contains('route') => MapsApiFailure.noRoute,
        // Function missing (not deployed) or not set up on the server.
        'not-found' || 'unimplemented' || 'failed-precondition' || 'permission-denied' => MapsApiFailure.notAvailable,
        'unavailable' || 'deadline-exceeded' => MapsApiFailure.offline,
        'resource-exhausted' => MapsApiFailure.busy,
        'invalid-argument' || 'out-of-range' => MapsApiFailure.invalid,
        _ => MapsApiFailure.failed,
      };
      if (failure == MapsApiFailure.notAvailable) {
        _available = false;
        Logger.w('[MapsApi] $name not available (${e.code}); maps server features off for this session');
      }
      throw MapsApiException(failure);
    } on MapsApiException {
      rethrow;
    } catch (e) {
      Logger.w('[MapsApi] $name failed: ${e.runtimeType}');
      throw const MapsApiException(MapsApiFailure.offline);
    }
  }

  @override
  Future<RouteSummary> route(GeoCoord origin, GeoCoord destination) async {
    if (!origin.isValid || !destination.isValid) throw const MapsApiException(MapsApiFailure.invalid);
    final key = '${_k(origin, 4)}>${_k(destination, 4)}';
    final hit = _routes[key];
    if (hit != null && _clock().difference(hit.at) < const Duration(minutes: 2)) return hit.value;
    final d = await _call('computeRoute', {'origin': _ll(origin), 'destination': _ll(destination)});
    final distance = d['distanceMeters'], duration = d['durationSeconds'], line = d['polyline'];
    if (distance is! num || duration is! num || line is! String) throw const MapsApiException(MapsApiFailure.failed);
    final List<GeoCoord> points;
    try {
      points = decodePolyline(line);
    } on FormatException {
      throw const MapsApiException(MapsApiFailure.failed);
    }
    final value = RouteSummary(distanceMeters: distance.round(), durationSeconds: duration.round(), points: points);
    if (_routes.length > 50) _routes.clear();
    _routes[key] = (at: _clock(), value: value);
    return value;
  }

  static MapPlace? _place(Object? raw) {
    if (raw is! Map) return null;
    final lat = raw['lat'], lng = raw['lng'], label = raw['label'];
    if (lat is! num || lng is! num || label is! String || label.isEmpty) return null;
    final point = GeoCoord(lat.toDouble(), lng.toDouble());
    if (!point.isValid) return null;
    return MapPlace(
      point: point,
      label: label,
      name: raw['name'] is String ? raw['name'] as String : '',
      city: raw['city'] is String ? raw['city'] as String : '',
    );
  }

  @override
  Future<List<MapPlace>> search(String query, {GeoCoord? near}) async {
    final q = query.trim();
    if (q.length < 3) throw const MapsApiException(MapsApiFailure.invalid);
    final d = await _call('searchPlaces', {'query': q, if (near != null && near.isValid) 'near': _ll(near)});
    final list = d['places'];
    if (list is! List) return const [];
    return [for (final p in list) ?_place(p)];
  }

  @override
  Future<MapPlace?> reverse(GeoCoord point) async {
    if (!point.isValid) throw const MapsApiException(MapsApiFailure.invalid);
    final key = _k(point, 5);
    final hit = _addresses[key];
    if (hit != null && _clock().difference(hit.at) < const Duration(hours: 1)) return hit.value;
    final d = await _call('reverseGeocode', {'point': _ll(point)});
    final value = _place(d['place']);
    if (_addresses.length > 200) _addresses.clear();
    _addresses[key] = (at: _clock(), value: value);
    return value;
  }
}

/// Overridden in tests.
final mapsApiProvider = Provider<MapsApi>((ref) => FunctionsMapsApi(() => ref.read(firebaseFunctionsProvider)));

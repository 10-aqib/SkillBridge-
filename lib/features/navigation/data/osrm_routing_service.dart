import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/utils/request_spacer.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';

/// OSRM `/route/v1` client (Navigation phase 5). Pure Dart.
///
/// The address and profile come from the build-time routing settings. The
/// public demo server (router.project-osrm.org) has no availability
/// guarantee and allows about one request a second, so requests to it are
/// spaced out; a self-hosted server isn't throttled.
class OsrmRoutingService extends RoutingService {
  OsrmRoutingService({
    required String baseUrl,
    this.profile = 'driving',
    http.Client? client,
    Duration? minGap,
    this.timeout = const Duration(seconds: 15),
    this.userAgent,
    DateTime Function()? clock,
  })  : baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _client = client ?? http.Client(),
        _ownsClient = client == null,
        _clock = clock ?? DateTime.now,
        _spacer = RequestSpacer(
          minGap ?? (Uri.tryParse(baseUrl)?.host == 'router.project-osrm.org' ? const Duration(seconds: 1) : Duration.zero),
        );

  final String baseUrl;
  final String profile;
  final Duration timeout;

  /// Sent outside browsers (browsers set their own).
  final String? userAgent;

  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _clock;
  final RequestSpacer _spacer;

  static const _cacheSize = 10;
  static const _cacheFor = Duration(minutes: 5);
  final _cache = <String, RouteResult>{};

  /// The request URL for a route (for tests and logs).
  Uri routeUri(LatLng origin, LatLng destination, {bool alternatives = true}) {
    String c(LatLng p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}';
    return Uri.parse('$baseUrl/route/v1/$profile/${c(origin)};${c(destination)}').replace(queryParameters: {
      'steps': 'true',
      'geometries': 'geojson',
      'overview': 'full',
      'alternatives': '$alternatives',
    });
  }

  @override
  Future<RouteResult> getRoute(LatLng origin, LatLng destination, {bool alternatives = true}) async {
    if (!isRoutablePoint(origin) || !isRoutablePoint(destination)) {
      throw const RoutingException(RoutingFailure.invalidInput, 'coordinates out of range');
    }
    final uri = routeUri(origin, destination, alternatives: alternatives);
    final key = uri.toString();
    final cached = _cache[key];
    if (cached != null && _clock().difference(cached.fetchedAt) < _cacheFor) return cached;

    final body = await _spacer.run(() => _fetch(uri));
    final result = parseResponse(body, origin: origin, destination: destination, fetchedAt: _clock());
    _cache.remove(key);
    _cache[key] = result;
    while (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return result;
  }

  Future<Object?> _fetch(Uri uri) async {
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: {
            'Accept': 'application/json',
            if (userAgent != null && !_isWeb) 'User-Agent': userAgent!,
          })
          .timeout(timeout);
    } on TimeoutException {
      throw const RoutingException(RoutingFailure.timeout);
    } catch (e) {
      throw RoutingException(RoutingFailure.network, e.runtimeType.toString());
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      json = null;
    }
    // OSRM explains refusals in the body (400 with a code), so read it first.
    final code = json is Map ? json['code'] : null;
    if (code is String && code != 'Ok') throw _failureFor(code, json is Map ? '${json['message'] ?? ''}' : '');
    if (res.statusCode == 429 || res.statusCode >= 500) {
      throw RoutingException(RoutingFailure.unavailable, 'HTTP ${res.statusCode}');
    }
    if (res.statusCode != 200 || json == null) {
      throw RoutingException(RoutingFailure.malformed, 'HTTP ${res.statusCode}');
    }
    return json;
  }

  static const _isWeb = bool.fromEnvironment('dart.library.js_interop');

  static RoutingException _failureFor(String code, String message) => switch (code) {
        'NoRoute' => RoutingException(RoutingFailure.noRoute, message),
        'NoSegment' => RoutingException(RoutingFailure.tooFarFromRoad, message),
        'InvalidQuery' || 'InvalidValue' || 'InvalidOptions' || 'InvalidUrl' || 'InvalidService' || 'InvalidVersion' || 'TooBig' =>
          RoutingException(RoutingFailure.invalidInput, '$code $message'),
        _ => RoutingException(RoutingFailure.unavailable, '$code $message'),
      };

  /// Furthest the engine may move a point to reach a road. OSRM always
  /// snaps to the nearest road, however far: a destination in the sea was
  /// moved 571 km in testing. Beyond this the route isn't to that place.
  static const maxSnapDistance = 2000.0;

  /// Turns an OSRM response into routes. Routes with no usable geometry are
  /// skipped; none left means [RoutingFailure.noRoute]. A point moved more
  /// than [maxSnapDistance] to reach a road is [RoutingFailure.tooFarFromRoad].
  static RouteResult parseResponse(Object? json, {required LatLng origin, required LatLng destination, required DateTime fetchedAt}) {
    if (json is! Map) throw const RoutingException(RoutingFailure.malformed, 'not an object');
    final code = json['code'];
    if (code is String && code != 'Ok') throw _failureFor(code, '${json['message'] ?? ''}');
    final raw = json['routes'];
    if (raw is! List) throw const RoutingException(RoutingFailure.malformed, 'no routes list');
    final routes = raw.whereType<Map>().map(parseRoute).whereType<NavRoute>().toList();
    if (routes.isEmpty) throw const RoutingException(RoutingFailure.noRoute, 'no usable route');
    final waypoints = json['waypoints'] is List ? (json['waypoints'] as List).whereType<Map>().toList() : const <Map>[];
    double? snap(int i) => i < waypoints.length && waypoints[i]['distance'] is num ? (waypoints[i]['distance'] as num).toDouble() : null;
    final fromSnap = snap(0), toSnap = waypoints.isEmpty ? null : snap(waypoints.length - 1);
    if ((fromSnap ?? 0) > maxSnapDistance) {
      throw RoutingException(RoutingFailure.tooFarFromRoad, 'start is ${fromSnap!.round()} m from a road');
    }
    if ((toSnap ?? 0) > maxSnapDistance) {
      throw RoutingException(RoutingFailure.tooFarFromRoad, 'destination is ${toSnap!.round()} m from a road');
    }
    return RouteResult(
      primary: routes.first,
      alternatives: routes.skip(1).toList(),
      origin: origin,
      destination: destination,
      fetchedAt: fetchedAt,
      originSnapDistance: fromSnap,
      destinationSnapDistance: toSnap,
    );
  }

  static double _num(Object? v) => v is num && v.isFinite ? v.toDouble() : 0;

  static List<LatLng> _line(Object? geometry) {
    if (geometry is! Map) return const [];
    final coords = geometry['coordinates'];
    if (coords is! List) return const [];
    final out = <LatLng>[];
    for (final c in coords) {
      if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
        final lng = (c[0] as num).toDouble(), lat = (c[1] as num).toDouble();
        if (lat.abs() <= 90 && lng.abs() <= 180) out.add(LatLng(lat, lng));
      }
    }
    return out;
  }

  static String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// One OSRM route, or null when it has no usable line.
  static NavRoute? parseRoute(Map route) {
    final points = _line(route['geometry']);
    if (points.length < 2) return null;
    final legs = <RouteLeg>[];
    for (final leg in (route['legs'] is List ? route['legs'] as List : const []).whereType<Map>()) {
      final steps = <RouteStep>[];
      for (final s in (leg['steps'] is List ? leg['steps'] as List : const []).whereType<Map>()) {
        final m = s['maneuver'] is Map ? s['maneuver'] as Map : const {};
        final loc = m['location'];
        final location = loc is List && loc.length >= 2 && loc[0] is num && loc[1] is num
            ? LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble())
            : null;
        final geometry = _line(s['geometry']);
        final at = location ?? (geometry.isNotEmpty ? geometry.first : null);
        if (at == null) continue;
        steps.add(RouteStep(
          maneuver: Maneuver(
            type: ManeuverType.parse(m['type'] as String?),
            modifier: TurnModifier.parse(m['modifier'] as String?),
            location: at,
            exit: m['exit'] is int ? m['exit'] as int : null,
            bearingBefore: m['bearing_before'] is num ? (m['bearing_before'] as num).toDouble() : null,
            bearingAfter: m['bearing_after'] is num ? (m['bearing_after'] as num).toDouble() : null,
          ),
          distance: _num(s['distance']),
          duration: _num(s['duration']),
          geometry: geometry,
          name: _text(s['name']) ?? '',
          ref: _text(s['ref']),
          destinations: _text(s['destinations']),
          rotaryName: _text(s['rotary_name']),
          mode: _text(s['mode']) ?? 'driving',
          drivingSide: _text(s['driving_side']) == 'left' ? 'left' : 'right',
        ));
      }
      legs.add(RouteLeg(steps: steps, distance: _num(leg['distance']), duration: _num(leg['duration']), summary: _text(leg['summary']) ?? ''));
    }
    return NavRoute(points: points, distance: _num(route['distance']), duration: _num(route['duration']), legs: legs);
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

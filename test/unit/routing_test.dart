import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/features/navigation/data/osrm_routing_service.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';

/// Real OSRM answers recorded in Lahore (test/fixtures/osrm).
String fixture(String name) => File('test/fixtures/osrm/$name.json').readAsStringSync();
Object? fixtureJson(String name) => jsonDecode(fixture(name));

const _minar = LatLng(31.5925, 74.3095);
const _badshahi = LatLng(31.5882, 74.3100);

RouteResult parse(String name, {LatLng from = _minar, LatLng to = _badshahi}) =>
    OsrmRoutingService.parseResponse(fixtureJson(name), origin: from, destination: to, fetchedAt: DateTime(2026, 11, 14));

OsrmRoutingService service(MockClient client, {String base = 'https://osrm.example.com', Duration? minGap, Duration? timeout}) =>
    OsrmRoutingService(baseUrl: base, client: client, minGap: minGap ?? Duration.zero, timeout: timeout ?? const Duration(seconds: 15), userAgent: 'SkillBridge/1.0 (test)');

void main() {
  group('parsing real OSRM routes', () {
    test('Minar-e-Pakistan → Badshahi Mosque: geometry, distance, time and every maneuver', () {
      final r = parse('lahore_route');
      final route = r.primary;
      expect(r.alternatives, isEmpty);
      expect(route.distance, closeTo(3672.6, 0.01));
      expect(route.duration, closeTo(666.3, 0.01));
      expect(route.points, hasLength(151));
      // GeoJSON is [lng, lat]: the line starts near the origin, in Lahore.
      expect(route.points.first.latitude, closeTo(31.59, 0.01));
      expect(route.points.first.longitude, closeTo(74.31, 0.01));
      final steps = route.steps;
      expect(steps, hasLength(9));
      expect(steps.map((s) => (s.maneuver.type, s.maneuver.modifier)).toList(), [
        (ManeuverType.depart, TurnModifier.left),
        (ManeuverType.turn, TurnModifier.left),
        (ManeuverType.turn, TurnModifier.sharpLeft),
        (ManeuverType.turn, TurnModifier.straight),
        (ManeuverType.turn, TurnModifier.slightLeft),
        (ManeuverType.turn, TurnModifier.left),
        (ManeuverType.turn, TurnModifier.sharpLeft),
        (ManeuverType.turn, TurnModifier.right),
        (ManeuverType.arrive, TurnModifier.right),
      ]);
      expect(steps[3].roadLabel, 'سرکلر روڈ', reason: 'Urdu road names are kept');
      expect(steps[4].roadLabel, 'Ravi Road');
      expect(steps.first.roadLabel, '', reason: 'unnamed road');
      expect(steps.fold<double>(0, (a, s) => a + s.distance), closeTo(route.distance, 1));
      expect(steps[1].maneuver.location.latitude, closeTo(31.59, 0.02));
      expect(steps[1].maneuver.bearingAfter, isNotNull);
    });

    test('Model Town → Johar Town: two alternatives, U-turn, ramps, merge and a roundabout', () {
      final r = parse('model_town_to_johar_town');
      expect(r.all, hasLength(2));
      expect(r.primary.distance, closeTo(7548, 1));
      expect(r.alternatives.single.distance, closeTo(9101, 1));
      expect(r.primary.summary, 'Maulana Shaukat Ali Road, Abdul Haq Road');
      final kinds = r.all.expand((x) => x.steps).map((s) => (s.maneuver.type, s.maneuver.modifier)).toSet();
      expect(kinds, containsAll({
        (ManeuverType.continueOn, TurnModifier.uturn),
        (ManeuverType.onRamp, TurnModifier.slightLeft),
        (ManeuverType.offRamp, TurnModifier.slightLeft),
        (ManeuverType.merge, TurnModifier.slightRight),
        (ManeuverType.roundabout, TurnModifier.left),
        (ManeuverType.exitRoundabout, TurnModifier.slightLeft),
        (ManeuverType.endOfRoad, TurnModifier.left),
      }));
      expect(r.primary.steps.map((s) => s.maneuver.type), isNot(contains(ManeuverType.unknown)));
    });

    test('Gulberg → DHA: rotary with its exit number and name', () {
      final r = parse('gulberg_to_dha');
      final rotary = r.primary.steps.firstWhere((s) => s.maneuver.type == ManeuverType.rotary);
      expect(rotary.maneuver.exit, 3);
      expect(rotary.rotaryName, 'Hussain Chowk');
      expect(rotary.maneuver.type.isRoundabout, isTrue);
      expect(r.primary.steps.any((s) => s.maneuver.type.isRoundaboutExit), isTrue);
    });

    test('how far each point was moved to a road is kept; a point far from any road is refused', () {
      final r = parse('lahore_route');
      expect(r.originSnapDistance, closeTo(91.3, 0.1));
      expect(r.destinationSnapDistance, closeTo(98.1, 0.1));

      // Shape of a real answer for a point in the Arabian Sea (moved 571 km).
      final sea = jsonDecode(fixture('lahore_route')) as Map<String, dynamic>;
      (sea['waypoints'] as List).last['distance'] = 571566.0;
      expect(
        () => OsrmRoutingService.parseResponse(sea, origin: _minar, destination: const LatLng(20, 64), fetchedAt: DateTime(2026)),
        throwsA(isA<RoutingException>()
            .having((e) => e.failure, 'failure', RoutingFailure.tooFarFromRoad)
            .having((e) => e.detail, 'detail', contains('destination'))),
      );
      final start = jsonDecode(fixture('lahore_route')) as Map<String, dynamic>;
      (start['waypoints'] as List).first['distance'] = 2500.0;
      expect(
        () => OsrmRoutingService.parseResponse(start, origin: _minar, destination: _badshahi, fetchedAt: DateTime(2026)),
        throwsA(isA<RoutingException>().having((e) => e.detail, 'detail', contains('start'))),
      );
    });

    test('broken routes are skipped; nothing usable is "no route"', () {
      final mixed = {
        'code': 'Ok',
        'routes': [
          {'geometry': {'coordinates': [[74.3, 31.5]]}, 'distance': 1, 'duration': 1, 'legs': []}, // one point
          jsonDecode(fixture('lahore_route'))['routes'][0],
        ],
      };
      expect(OsrmRoutingService.parseResponse(mixed, origin: _minar, destination: _badshahi, fetchedAt: DateTime(2026)).all, hasLength(1));
      expect(
        () => OsrmRoutingService.parseResponse({'code': 'Ok', 'routes': []}, origin: _minar, destination: _badshahi, fetchedAt: DateTime(2026)),
        throwsA(isA<RoutingException>().having((e) => e.failure, 'failure', RoutingFailure.noRoute)),
      );
      expect(
        () => OsrmRoutingService.parseResponse('nonsense', origin: _minar, destination: _badshahi, fetchedAt: DateTime(2026)),
        throwsA(isA<RoutingException>().having((e) => e.failure, 'failure', RoutingFailure.malformed)),
      );
    });
  });

  group('OSRM requests', () {
    test('asks for steps, GeoJSON, the full line and alternatives, with lng,lat order', () async {
      late http.Request asked;
      final s = service(MockClient((r) async {
        asked = r;
        return http.Response.bytes(utf8.encode(fixture('lahore_route')), 200);
      }));
      final r = await s.getRoute(_minar, _badshahi);
      expect(r.primary.steps, hasLength(9));
      expect(asked.url.path, '/route/v1/driving/74.309500,31.592500;74.310000,31.588200');
      expect(asked.url.queryParameters, {'steps': 'true', 'geometries': 'geojson', 'overview': 'full', 'alternatives': 'true'});
      expect(asked.headers['User-Agent'], 'SkillBridge/1.0 (test)');
    });

    test('the same request is answered from a short cache', () async {
      var calls = 0;
      final s = service(MockClient((r) async {
        calls++;
        return http.Response.bytes(utf8.encode(fixture('lahore_route')), 200);
      }));
      await s.getRoute(_minar, _badshahi);
      await s.getRoute(_minar, _badshahi);
      expect(calls, 1);
      await s.getRoute(_minar, _badshahi, alternatives: false);
      expect(calls, 2, reason: 'a different request');
    });

    test('impossible coordinates fail before any request', () async {
      var calls = 0;
      final s = service(MockClient((r) async {
        calls++;
        return http.Response('{}', 200);
      }));
      for (final bad in [const LatLng(0, 0), LatLng(double.nan, 74.3)]) {
        await expectLater(s.getRoute(bad, _badshahi), throwsA(isA<RoutingException>().having((e) => e.failure, 'f', RoutingFailure.invalidInput)));
      }
      expect(calls, 0);
    });

    Future<RoutingFailure> failureOf(MockClient c, {Duration? timeout}) async {
      try {
        await service(c, timeout: timeout).getRoute(_minar, _badshahi);
      } on RoutingException catch (e) {
        return e.failure;
      }
      fail('expected a RoutingException');
    }

    test('engine refusals, server trouble, bad answers, no connection and timeouts are told apart', () async {
      expect(await failureOf(MockClient((r) async => http.Response('{"code":"NoRoute","message":"Impossible route between points"}', 200))),
          RoutingFailure.noRoute);
      expect(await failureOf(MockClient((r) async => http.Response('{"code":"NoSegment","message":"Could not find a matching segment for coordinate 0"}', 400))),
          RoutingFailure.tooFarFromRoad);
      expect(await failureOf(MockClient((r) async => http.Response('{"code":"InvalidQuery","message":"Query string malformed"}', 400))),
          RoutingFailure.invalidInput);
      expect(await failureOf(MockClient((r) async => http.Response('<html>Too Many Requests</html>', 429))), RoutingFailure.unavailable);
      expect(await failureOf(MockClient((r) async => http.Response('<html>Bad gateway</html>', 502))), RoutingFailure.unavailable);
      expect(await failureOf(MockClient((r) async => http.Response('not json', 200))), RoutingFailure.malformed);
      expect(await failureOf(MockClient((r) async => throw const SocketException('offline'))), RoutingFailure.network);
      expect(
        await failureOf(MockClient((r) => Completer<http.Response>().future), timeout: const Duration(milliseconds: 50)),
        RoutingFailure.timeout,
      );
    });

    test('connection and server trouble are worth retrying; a missing route is not', () {
      expect(const RoutingException(RoutingFailure.network).isTransient, isTrue);
      expect(const RoutingException(RoutingFailure.timeout).isTransient, isTrue);
      expect(const RoutingException(RoutingFailure.unavailable).isTransient, isTrue);
      expect(const RoutingException(RoutingFailure.noRoute).isTransient, isFalse);
      expect(const RoutingException(RoutingFailure.tooFarFromRoad).isTransient, isFalse);
    });

    test('the public demo server is limited to one request a second; a self-hosted one is not', () async {
      final times = <DateTime>[];
      MockClient recording() => MockClient((r) async {
            times.add(DateTime.now());
            return http.Response.bytes(utf8.encode(fixture('lahore_route')), 200);
          });
      final demo = OsrmRoutingService(baseUrl: 'https://router.project-osrm.org', client: recording());
      await Future.wait([demo.getRoute(_minar, _badshahi), demo.getRoute(_minar, const LatLng(31.58, 74.31))]);
      expect(times[1].difference(times[0]).inMilliseconds, greaterThanOrEqualTo(950));

      times.clear();
      final own = OsrmRoutingService(baseUrl: 'https://osrm.example.com', client: recording());
      await Future.wait([own.getRoute(_minar, _badshahi), own.getRoute(_minar, const LatLng(31.58, 74.31))]);
      expect(times[1].difference(times[0]).inMilliseconds, lessThan(500));
    });

    test('unconfigured routing fails as "unavailable"', () async {
      await expectLater(const UnavailableRoutingService().getRoute(_minar, _badshahi),
          throwsA(isA<RoutingException>().having((e) => e.failure, 'f', RoutingFailure.unavailable)));
    });
  });

  group('distance along the road', () {
    final route = parse('model_town_to_johar_town').primary;
    final line = RouteLine(route.points);

    test('the line length matches the engine\'s road distance', () {
      expect(line.length, closeTo(route.distance, route.distance * 0.01));
    });

    test('a point on the route snaps onto it; one beside it reports how far off it is', () {
      // 1.2 km in: Lane 48, where the route doesn't double back (the U-turn
      // at ~2.8 km brings it back along the same road).
      final mid = line.pointAt(1200);
      final on = line.snap(mid);
      expect(on.distanceToRoute, lessThan(1));
      expect(on.distanceAlong, closeTo(1200, 2));
      expect(line.remainingFrom(on), closeTo(line.length - 1200, 2));

      // 50 m to the side of the route, at right angles to it.
      final a = line.points[on.segment], b = line.points[on.segment + 1];
      final heading = const Distance().bearing(a, b);
      final beside = const Distance().offset(mid, 50, heading + 90);
      final off = line.snap(beside);
      expect(off.distanceToRoute, closeTo(50, 3));
    });

    test('snapping can start from the current segment so a later point never jumps back', () {
      final early = line.snap(line.pointAt(500));
      final later = line.snap(line.pointAt(4000), fromSegment: early.segment);
      expect(later.distanceAlong, greaterThan(early.distanceAlong));
      final limited = line.snap(line.pointAt(4000), fromSegment: early.segment, lookAhead: 2);
      expect(limited.distanceToRoute, greaterThan(100), reason: 'outside the look-ahead window');
    });

    test('time left uses each step\'s own time', () {
      final total = remainingDurationAt(route, 0);
      expect(total, closeTo(route.duration, route.duration * 0.02));
      // Step lengths add up to the route length to within a metre or so.
      expect(remainingDurationAt(route, route.distance), closeTo(0, 0.5));
      final half = remainingDurationAt(route, route.distance / 2);
      expect(half, inExclusiveRange(0, total));
    });

    test('service helpers: road distance left and arrival time', () {
      final s = service(MockClient((r) async => http.Response('{}', 200)));
      final start = route.points.first;
      expect(s.calculateDistance(route, start), closeTo(line.length, 5));
      final now = DateTime(2026, 11, 14, 10);
      final eta = s.estimateArrival(route, start, now: now);
      expect(eta.difference(now).inSeconds, closeTo(route.duration, route.duration * 0.02));
      expect(s.parseRouteSteps(route), hasLength(route.steps.length));
      expect(estimateArrival(now, -5), now, reason: 'never in the past');
    });
  });
}

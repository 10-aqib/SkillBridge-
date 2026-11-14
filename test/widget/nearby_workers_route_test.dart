import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/providers/location_provider.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/client/domain/entities/nearby_worker_entity.dart';
import 'package:skill_bridge/features/client/presentation/providers/nearby_workers_provider.dart';
import 'package:skill_bridge/features/client/presentation/screens/nearby_workers_screen.dart';
import 'package:skill_bridge/features/navigation/data/osrm_routing_service.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/routing_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/widgets/route_layer.dart';

import '../helpers/test_app.dart';

/// Routing for widget tests: the recorded Minar-e-Pakistan → Badshahi Mosque
/// answer, or a failure.
class FakeRouting extends RoutingService {
  FakeRouting({this.fail = false});
  final bool fail;
  final calls = <(LatLng, LatLng)>[];

  @override
  Future<RouteResult> getRoute(LatLng origin, LatLng destination, {bool alternatives = true}) async {
    calls.add((origin, destination));
    if (fail) throw const RoutingException(RoutingFailure.network);
    return OsrmRoutingService.parseResponse(
      jsonDecode(File('test/fixtures/osrm/lahore_route.json').readAsStringSync()),
      origin: origin,
      destination: destination,
      fetchedAt: DateTime.now(),
    );
  }
}

Position _here() => Position(
      latitude: 31.5925,
      longitude: 74.3095,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

final _workers = [
  NearbyWorkerEntity(
    workerId: 'w1',
    name: 'Bilal Ahmed',
    category: 'Plumber',
    hourlyRate: 800,
    rating: 4.6,
    location: GeoPointLocation(latitude: 31.5882, longitude: 74.3100),
    distanceKm: 0.5,
  ),
];

Future<void> steps(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('the same place is the same nearby-search key (no stream restart on rebuild)', () {
    const a = GeoPointLocation(latitude: 31.5925, longitude: 74.3095);
    const b = GeoPointLocation(latitude: 31.5925, longitude: 74.3095);
    expect(NearbyWorkerParams(a, 5), NearbyWorkerParams(b, 5));
    expect(NearbyWorkerParams(a, 5).hashCode, NearbyWorkerParams(b, 5).hashCode);
    expect(NearbyWorkerParams(a, 5), isNot(NearbyWorkerParams(a, 10)));
  });

  Future<FakeRouting> open(WidgetTester tester, {bool fail = false}) async {
    final routing = FakeRouting(fail: fail);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(
      overrides: [
        locationProvider.overrideWith((ref) async => _here()),
        nearbyWorkersProvider.overrideWith((ref, params) => Stream.value(_workers)),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
        routingServiceProvider.overrideWithValue(routing),
      ],
      home: const NearbyWorkersScreen(),
    ));
    await steps(tester);
    return routing;
  }

  testWidgets('the list shows the straight-line distance only, with no made-up travel time', (tester) async {
    await open(tester);
    expect(find.text('500 m away'), findsWidgets);
    expect(find.textContaining('min away'), findsNothing);
  });

  testWidgets('choosing a worker on the map draws the road route and shows road distance and time', (tester) async {
    final routing = await open(tester);
    await tester.tap(find.byTooltip('Map View'));
    await steps(tester);
    expect(find.byType(SbRouteLayer), findsNothing, reason: 'no route until a worker is chosen');

    await tester.tap(find.text('Bilal'));
    await steps(tester);
    expect(routing.calls, hasLength(1));
    expect(routing.calls.single.$1, const LatLng(31.5925, 74.3095));
    expect(routing.calls.single.$2, const LatLng(31.5882, 74.3100));
    expect(find.byType(SbRouteLayer), findsOneWidget);
    // 3,672.6 m and 666 s in the recorded answer.
    expect(find.text('3.7 km by road · ~12 min'), findsOneWidget);
  });

  testWidgets('if routing fails no line is drawn and the distance stays straight-line', (tester) async {
    await open(tester, fail: true);
    await tester.tap(find.byTooltip('Map View'));
    await steps(tester);
    await tester.tap(find.text('Bilal'));
    await steps(tester);
    expect(find.byType(SbRouteLayer), findsNothing);
    expect(find.textContaining('by road'), findsNothing);
    expect(find.text('500 m away'), findsWidgets);
  });
}

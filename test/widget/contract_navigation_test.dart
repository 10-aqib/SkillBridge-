import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/map_unavailable.dart';
import 'package:skill_bridge/core/map/maps_api.dart';
import 'package:skill_bridge/core/map/maps_config.dart';
import 'package:skill_bridge/core/map/sb_google_map.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/data/models/live_location.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/contract_navigation_screen.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/contract_tracking_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_contracts.dart';
import '../helpers/fake_location.dart';
import '../helpers/fake_map.dart';
import '../helpers/fake_maps_api.dart';
import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

Future<void> steps(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final client = testUser('client_1');
  final worker = testUser('w1', role: 'worker', name: 'Bilal Ahmed');
  const start = GeoCoord(31.5204, 74.3587);
  const pin = GeoCoord(31.5497, 74.3436);
  GeoPoint gp(GeoCoord p) => GeoPoint(p.latitude, p.longitude);

  late FakeTrackSource source;
  late FakeContractStore store;
  late FakeContractActions actions;
  late FakeLiveSink sink;

  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    required UserEntity user,
    Map<String, dynamic> contract = const {},
    LiveLocation? live,
    Stream<LiveLocation?>? liveStream,
    FakeMaps? maps,
    FakeMapsApi? api,
    bool locationAllowed = false,
    GeoFix? fix,
  }) async {
    source = FakeTrackSource()..oneShot = fix;
    store = FakeContractStore({'k1': contractDoc(extra: contract)});
    actions = FakeContractActions(store);
    sink = FakeLiveSink();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(testApp(
      overrides: [
        contractRemoteDataSourceProvider.overrideWithValue(store),
        contractActionsProvider.overrideWithValue(actions),
        currentUserProvider.overrideWith((ref) => user),
        locationSourceProvider.overrideWithValue(source),
        liveLocationSinkProvider.overrideWithValue(sink),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
        // null: no live document (not sharing).
        contractLiveLocationProvider('k1').overrideWith((ref) => liveStream ?? Stream.value(live)),
        if (maps != null) ...maps.overrides,
        mapsApiProvider.overrideWithValue(api ?? FakeMapsApi(available: false)),
        mapMyLocationAllowedProvider.overrideWith((ref) async => locationAllowed),
      ],
      home: screen,
    ));
    await steps(tester);
  }

  group('worker directions (ContractNavigationScreen)', () {
    testWidgets('only the hired worker, only while the job is active', (tester) async {
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: client, contract: {'serviceLocation': gp(pin)});
      expect(find.text(l.navOnlyWorker), findsOneWidget);
      expect(find.text(l.navOpenGoogleMaps), findsNothing);

      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker,
          contract: {'serviceLocation': gp(pin), 'status': 'completed', 'completedAt': Timestamp.now()});
      expect(find.text(l.navJobClosed), findsOneWidget);
      expect(source.watches, isEmpty, reason: 'GPS never started');
    });

    testWidgets('no pin yet: explained, nothing guessed', (tester) async {
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker, contract: {'serviceAddress': 'House 5, Street 2'});
      expect(find.text(l.navErrNoDestination), findsOneWidget);
      final directions = tester.widget<ButtonStyleButton>(
          find.ancestor(of: find.text(l.navOpenGoogleMaps), matching: find.bySubtype<ButtonStyleButton>()).first);
      expect(directions.onPressed, isNull, reason: 'no destination to send to Google Maps');
    });

    testWidgets('to the pinned place; directions hand off to Google Maps; share live location; tell the client and start work', (tester) async {
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker,
          contract: {'serviceLocation': gp(pin), 'serviceAddress': 'House 5, Street 2'});
      expect(find.text(l.navRouteTo('House 5, Street 2')), findsOneWidget);
      expect(find.text('31.54970, 74.34360'), findsOneWidget);
      expect(find.byType(SbMapUnavailable), findsOneWidget);
      final directions = tester.widget<ButtonStyleButton>(
          find.ancestor(of: find.text(l.navOpenGoogleMaps), matching: find.bySubtype<ButtonStyleButton>()).first);
      expect(directions.onPressed, isNotNull);
      expect(source.watches, isEmpty, reason: 'no in-app guidance, so no GPS stream until sharing starts');

      // Share: consent first, then the position goes out.
      await tester.tap(find.byTooltip(l.liveStartSharing));
      await steps(tester);
      expect(find.text(l.liveConsentTitle), findsOneWidget);
      source.oneShot = GeoFix(lat: start.latitude, lng: start.longitude, accuracy: 6, takenAt: DateTime.now());
      await tester.tap(find.text(l.liveConsentAgree));
      await steps(tester);
      expect(sink.writes.first, startsWith('start:k1:w1'));
      expect(find.byTooltip(l.liveStopSharing), findsOneWidget);

      await tester.tap(find.text(l.navArrivedTell('Ayesha Khan')));
      await steps(tester);
      expect(actions.calls.where((c) => c.startsWith('update:k1:')), hasLength(1));
      expect(actions.calls.last, endsWith(':${l.navArrivedNote}'));
      expect(find.text(l.navArrivedSent('Ayesha Khan')), findsWidgets);
      expect(find.widgetWithText(SnackBar, l.navArrivedSent('Ayesha Khan')), findsNothing, reason: 'the button confirms inline');
      // Let the "sharing started" snack bar go before tapping under it.
      await tester.pump(const Duration(seconds: 6));
      await steps(tester);

      await tester.tap(find.text(l.contractStart));
      await steps(tester);
      expect(actions.calls.last, 'start:k1');
      expect(find.text(l.contractStart), findsNothing, reason: 'work started');
    });
  });

  group('client live map (ContractTrackingScreen)', () {
    LiveLocation fresh(GeoCoord p, {double? heading}) =>
        LiveLocation(lat: p.latitude, lng: p.longitude, accuracy: 15, heading: heading, speed: heading == null ? null : 8, updatedAt: DateTime.now());

    testWidgets('live: the worker position, accuracy and a Google Maps link; no made-up route or time', (tester) async {
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: fresh(start, heading: 90));
      expect(find.text(l.liveBadge), findsOneWidget);
      expect(find.text(l.liveOpenInMaps), findsOneWidget);
      expect(find.textContaining('by road'), findsNothing);
      expect(find.textContaining('Arrives about'), findsNothing);
    });

    testWidgets('an old position is never shown as live: a warning instead', (tester) async {
      final old = LiveLocation(lat: start.latitude, lng: start.longitude, accuracy: 15, updatedAt: DateTime.now().subtract(const Duration(minutes: 6)));
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client, contract: {'serviceLocation': gp(pin)}, live: old);
      expect(find.text(l.liveBadgeStale), findsOneWidget);
      expect(find.text(l.liveClientStale('Bilal Ahmed')), findsOneWidget);
      expect(find.text(l.liveBadge), findsNothing);
    });

    testWidgets('not sharing, no pin, and arrived are each explained', (tester) async {
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client, contract: {'serviceLocation': gp(pin)});
      expect(find.text(l.liveClientNotSharing('Bilal Ahmed')), findsOneWidget);

      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client, live: fresh(start));
      expect(find.text(l.trackNoPin), findsOneWidget);

      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: fresh(GeoCoord(pin.latitude + 20 / 111320, pin.longitude)));
      expect(find.text(l.trackArrived('Bilal Ahmed')), findsOneWidget);
    });

    testWidgets('only the client of the job', (tester) async {
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: worker, contract: {'serviceLocation': gp(pin)}, live: fresh(start));
      expect(find.text(l.trackOnlyClient), findsOneWidget);
    });
  });

  group('with Google Maps', () {
    LiveLocation liveAt(GeoCoord p, {Duration age = Duration.zero}) =>
        LiveLocation(lat: p.latitude, lng: p.longitude, accuracy: 15, updatedAt: DateTime.now().subtract(age));

    testWidgets('worker directions: the pinned place as the destination marker, blue dot allowed', (tester) async {
      final maps = FakeMaps();
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker,
          contract: {'serviceLocation': gp(pin), 'serviceAddress': 'House 5, Street 2'}, maps: maps);
      expect(find.byType(SbMapUnavailable), findsNothing);
      expect(maps.marker('destination')!.position, pin);
      expect(maps.marker('destination')!.kind, SbMarkerKind.destination);
      expect(maps.spec!.initialCenter, pin);
    });

    testWidgets('worker directions without a pin draw no map at all', (tester) async {
      final maps = FakeMaps();
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker, contract: {'serviceAddress': 'House 5'}, maps: maps);
      expect(maps.spec, isNull);
      expect(find.text(l.navErrNoDestination), findsOneWidget);
    });

    testWidgets('client tracking: worker and pin markers, accuracy circle, framed on each update until the map is touched', (tester) async {
      final maps = FakeMaps();
      final live = StreamController<LiveLocation?>();
      addTearDown(live.close);
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, liveStream: live.stream, maps: maps);
      live.add(liveAt(start));
      await steps(tester);
      expect(maps.marker('worker')!.position, start);
      expect(maps.marker('worker')!.stale, isFalse);
      expect(maps.marker('pin')!.position, pin);
      expect(maps.spec!.circles.single.radiusMetres, 15);
      expect(maps.controller.lastFit, [start, pin]);

      const nearer = GeoCoord(31.5300, 74.3500);
      live.add(liveAt(nearer));
      await steps(tester);
      expect(maps.controller.lastFit, [nearer, pin], reason: 'follows the worker');

      // The client moves the map: stop following.
      await tester.tap(find.byKey(const Key('fake-google-map')));
      final fits = maps.controller.calls.where((c) => c.startsWith('fit')).length;
      live.add(liveAt(start));
      await steps(tester);
      expect(maps.controller.calls.where((c) => c.startsWith('fit')).length, fits);

      // Recenter follows again.
      await tester.tap(find.byTooltip(l.mapRecenter));
      await steps(tester);
      expect(maps.controller.lastFit, [start, pin]);
    });

    testWidgets('client tracking: road route from the live worker to the pin, distance and arrival time', (tester) async {
      final maps = FakeMaps();
      final api = FakeMapsApi(routeResult: const RouteSummary(distanceMeters: 4210, durationSeconds: 754, points: [start, GeoCoord(31.535, 74.35), pin]));
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: liveAt(start), maps: maps, api: api);
      expect(api.routes.single, (start, pin));
      expect(maps.spec!.polylines.single.points, hasLength(3));
      expect(find.text(l.trackRoadLeft('4.2 km', '13 min')), findsOneWidget);
      expect(find.textContaining('Arrives about'), findsOneWidget);
      expect(find.text(l.navEstimateNote), findsOneWidget);
    });

    testWidgets('client tracking: a small move reuses the route; a 150 m+ move asks again', (tester) async {
      final api = FakeMapsApi();
      final live = StreamController<LiveLocation?>();
      addTearDown(live.close);
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, liveStream: live.stream, maps: FakeMaps(), api: api);
      live.add(liveAt(start));
      await steps(tester);
      expect(api.routes, hasLength(1));
      live.add(liveAt(GeoCoord(start.latitude + 50 / 111320, start.longitude)));
      await steps(tester);
      expect(api.routes, hasLength(1), reason: '50 m: same route');
      live.add(liveAt(GeoCoord(start.latitude + 300 / 111320, start.longitude)));
      await steps(tester);
      expect(api.routes, hasLength(2));
    });

    testWidgets('client tracking: no route for an old position; a failed route is explained', (tester) async {
      var api = FakeMapsApi();
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: liveAt(start, age: const Duration(minutes: 6)), maps: FakeMaps(), api: api);
      expect(api.routes, isEmpty);
      expect(find.textContaining('by road'), findsNothing);

      api = FakeMapsApi(routeFailure: MapsApiFailure.noRoute);
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: liveAt(start), maps: FakeMaps(), api: api);
      expect(find.text(l.trackNoRoute), findsOneWidget);
    });

    testWidgets('worker directions: with location allowed, the road route from here with distance and time', (tester) async {
      final maps = FakeMaps();
      final api = FakeMapsApi();
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker,
          contract: {'serviceLocation': gp(pin), 'serviceAddress': 'House 5, Street 2'}, maps: maps, api: api, locationAllowed: true,
          fix: GeoFix(lat: start.latitude, lng: start.longitude, accuracy: 6, takenAt: DateTime.now()));
      await steps(tester);
      expect(api.routes.single, (start, pin));
      expect(find.text(l.trackRoadLeft('4.2 km', '13 min')), findsOneWidget);
      expect(maps.spec!.polylines, hasLength(1));
      expect(maps.controller.lastFit, contains(start));
    });

    testWidgets('worker directions: location not allowed means no GPS request and no route', (tester) async {
      final api = FakeMapsApi();
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker,
          contract: {'serviceLocation': gp(pin)}, maps: FakeMaps(), api: api);
      expect(api.routes, isEmpty);
      expect(source.oneShotRequests, 0);
    });

    testWidgets('client tracking: an old position is a faded marker', (tester) async {
      final maps = FakeMaps();
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: liveAt(start, age: const Duration(minutes: 6)), maps: maps);
      expect(maps.marker('worker')!.stale, isTrue);
    });
  });
}

/// Records live-location writes.
class FakeLiveSink implements LiveLocationSink {
  final writes = <String>[];
  @override
  Future<void> start(String contractId, String workerId, GeoFix fix) async => writes.add('start:$contractId:$workerId');
  @override
  Future<void> update(String contractId, GeoFix fix) async => writes.add('update:$contractId');
  @override
  Future<void> remove(String contractId) async => writes.add('remove:$contractId');
}

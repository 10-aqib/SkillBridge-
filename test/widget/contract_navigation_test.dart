import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/data/models/live_location.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/routing_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/screen_awake.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/voice_guidance.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/contract_navigation_screen.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/contract_tracking_screen.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:skill_bridge/features/navigation/presentation/widgets/route_layer.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_contracts.dart';
import '../helpers/fake_location.dart';
import '../helpers/fake_navigation.dart';
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
  final lahore = recordedRoute('lahore_route').primary;
  final line = RouteLine(lahore.points);
  final start = lahore.points.first;
  final pin = lahore.points.last;
  GeoPoint gp(LatLng p) => GeoPoint(p.latitude, p.longitude);
  GeoFix at(LatLng p) => GeoFix(lat: p.latitude, lng: p.longitude, accuracy: 6);

  late FakeTrackSource source;
  late FakeRouting routing;
  late FakeContractStore store;
  late FakeContractActions actions;
  late FakeLiveSink sink;

  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    required UserEntity user,
    Map<String, dynamic> contract = const {},
    LiveLocation? live,
  }) async {
    source = FakeTrackSource();
    routing = FakeRouting();
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
        routingServiceProvider.overrideWithValue(routing),
        screenAwakeProvider.overrideWithValue(FakeScreenAwake()),
        speakerProvider.overrideWithValue(FakeSpeaker()),
        liveLocationSinkProvider.overrideWithValue(sink),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
        // null: no live document (not sharing).
        contractLiveLocationProvider('k1').overrideWith((ref) => Stream.value(live)),
      ],
      home: screen,
    ));
    await steps(tester);
  }

  group('worker directions (ContractNavigationScreen)', () {
    testWidgets('only the hired worker, only while the job is active', (tester) async {
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: client, contract: {'serviceLocation': gp(pin)});
      expect(find.text(l.navOnlyWorker), findsOneWidget);
      expect(find.byType(NavigationScreen), findsNothing);

      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker,
          contract: {'serviceLocation': gp(pin), 'status': 'completed', 'completedAt': Timestamp.now()});
      expect(find.text(l.navJobClosed), findsOneWidget);
      expect(source.watches, isEmpty, reason: 'GPS never started');
    });

    testWidgets('no pin yet: explained, nothing guessed', (tester) async {
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker, contract: {'serviceAddress': 'House 5, Street 2'});
      expect(find.text(l.navErrNoDestination), findsOneWidget);
      expect(routing.calls, isEmpty);
    });

    testWidgets('to the pinned place; share live location from the map; on arrival tell the client and start work', (tester) async {
      await open(tester, const ContractNavigationScreen(contractId: 'k1'), user: worker,
          contract: {'serviceLocation': gp(pin), 'serviceAddress': 'House 5, Street 2'});
      source.emit(at(start));
      await steps(tester);
      expect(routing.calls.single.$2, pin, reason: 'routed to the client\'s pin');
      expect(find.text(l.navRouteTo('House 5, Street 2')), findsOneWidget);
      await tester.tap(find.text(l.navStart));
      await steps(tester);

      // Share from the map: consent first, then the position goes out.
      await tester.tap(find.byTooltip(l.liveStartSharing));
      await steps(tester);
      expect(find.text(l.liveConsentTitle), findsOneWidget);
      source.oneShot = GeoFix(lat: start.latitude, lng: start.longitude, accuracy: 6, takenAt: DateTime.now());
      await tester.tap(find.text(l.liveConsentAgree));
      await steps(tester);
      expect(sink.writes.first, startsWith('start:k1:w1'));
      expect(find.byTooltip(l.liveStopSharing), findsOneWidget);

      for (var along = 200.0; along < line.length - 50; along += 200) {
        source.emit(at(line.pointAt(along)));
        await steps(tester, 2);
      }
      source.emit(at(pin));
      await steps(tester);
      expect(find.text(l.navArrivedTitle), findsOneWidget);

      await tester.tap(find.text(l.navArrivedTell('Ayesha Khan')));
      await steps(tester);
      expect(actions.calls.where((c) => c.startsWith('update:k1:')), hasLength(1));
      expect(actions.calls.last, endsWith(':${l.navArrivedNote}'));
      expect(find.text(l.navArrivedSent('Ayesha Khan')), findsWidgets);

      await tester.tap(find.text(l.contractStart));
      await steps(tester);
      expect(actions.calls.last, 'start:k1');
      expect(find.text(l.contractStart), findsNothing, reason: 'work started');
    });
  });

  group('client live map (ContractTrackingScreen)', () {
    LiveLocation fresh(LatLng p, {double? heading}) =>
        LiveLocation(lat: p.latitude, lng: p.longitude, accuracy: 15, heading: heading, speed: heading == null ? null : 8, updatedAt: DateTime.now());

    testWidgets('live: the worker with direction, the pin, the road route and time left', (tester) async {
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: fresh(start, heading: 90));
      expect(find.text(l.liveBadge), findsOneWidget);
      expect(routing.calls.single, (start, pin));
      expect(find.byType(SbRouteLayer), findsOneWidget);
      expect(find.text(l.trackRoadLeft('3.7 km', '12 min')), findsOneWidget);
      expect(find.textContaining('Arrives about'), findsOneWidget);
    });

    testWidgets('an old position is never shown as live: no route, no time, a warning', (tester) async {
      final old = LiveLocation(lat: start.latitude, lng: start.longitude, accuracy: 15, updatedAt: DateTime.now().subtract(const Duration(minutes: 6)));
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client, contract: {'serviceLocation': gp(pin)}, live: old);
      expect(find.text(l.liveBadgeStale), findsOneWidget);
      expect(find.text(l.liveClientStale('Bilal Ahmed')), findsOneWidget);
      expect(find.byType(SbRouteLayer), findsNothing);
      expect(find.textContaining('by road'), findsNothing);
      expect(routing.calls, isEmpty);
    });

    testWidgets('not sharing, no pin, and arrived are each explained', (tester) async {
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client, contract: {'serviceLocation': gp(pin)});
      expect(find.text(l.liveClientNotSharing('Bilal Ahmed')), findsOneWidget);

      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client, live: fresh(start));
      expect(find.text(l.trackNoPin), findsOneWidget);

      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: client,
          contract: {'serviceLocation': gp(pin)}, live: fresh(const Distance().offset(pin, 20, 0)));
      expect(find.text(l.trackArrived('Bilal Ahmed')), findsOneWidget);
    });

    testWidgets('only the client of the job', (tester) async {
      await open(tester, const ContractTrackingScreen(contractId: 'k1'), user: worker, contract: {'serviceLocation': gp(pin)}, live: fresh(start));
      expect(find.text(l.trackOnlyClient), findsOneWidget);
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

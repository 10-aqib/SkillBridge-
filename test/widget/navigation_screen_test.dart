import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/routing_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/navigation_controller.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/screen_awake.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/voice_guidance.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:skill_bridge/features/navigation/presentation/widgets/nav_panels.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_location.dart';
import '../helpers/fake_navigation.dart';
import '../helpers/test_app.dart';

Future<void> steps(WidgetTester tester, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final lahore = recordedRoute('lahore_route').primary;
  final line = RouteLine(lahore.points);
  GeoFix at(LatLng p) => GeoFix(lat: p.latitude, lng: p.longitude, accuracy: 6);

  late FakeTrackSource source;
  late FakeRouting routing;
  late FakeScreenAwake awake;
  late FakeSpeaker speaker;
  var now = DateTime(2026, 11, 14, 10);

  /// A home screen with a button that opens navigation (so closing pops).
  Future<void> open(WidgetTester tester, {LatLng? destination, String? label = 'Badshahi Mosque', void Function()? configure}) async {
    source = FakeTrackSource();
    routing = FakeRouting();
    awake = FakeScreenAwake();
    speaker = FakeSpeaker();
    configure?.call();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(
      overrides: [
        locationSourceProvider.overrideWithValue(source),
        routingServiceProvider.overrideWithValue(routing),
        screenAwakeProvider.overrideWithValue(awake),
        speakerProvider.overrideWithValue(speaker),
        navigationControllerProvider.overrideWith(() => NavigationController(clock: () => now)),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NavigationScreen(destination: destination, label: label))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await steps(tester);
  }

  Future<void> toReady(WidgetTester tester) async {
    await open(tester, destination: lahore.points.last);
    expect(find.text(l.pickerLocating), findsOneWidget);
    source.emit(at(lahore.points.first));
    await steps(tester);
  }

  testWidgets('before starting: the route, its time and distance, the estimate note and Start', (tester) async {
    await toReady(tester);
    expect(find.text(l.navRouteTo('Badshahi Mosque')), findsOneWidget);
    expect(find.text('12 min · 3.7 km'), findsOneWidget);
    expect(find.textContaining(l.navFastest), findsOneWidget);
    expect(find.text(l.navEstimateNote), findsOneWidget);
    expect(find.text(l.navStart), findsOneWidget);
    expect(awake.on, isFalse, reason: 'the screen is held on only while guiding');
  });

  testWidgets('guiding: next turn with distance, time and distance left, arrival time, End; then arrival', (tester) async {
    await toReady(tester);
    await tester.tap(find.text(l.navStart));
    await steps(tester);
    expect(find.byType(NavInstructionCard), findsOneWidget);
    expect(find.text('Turn left'), findsOneWidget);
    expect(find.text('950 m'), findsOneWidget, reason: '949 m to the first turn');
    expect(find.text('12 min'), findsOneWidget);
    expect(find.textContaining('3.7 km · Arrive'), findsOneWidget);
    expect(find.text(l.navEnd), findsOneWidget);
    expect(awake.on, isTrue);

    // Drive past the first turn.
    for (var along = 100.0; along <= 1000; along += 100) {
      source.emit(at(line.pointAt(along)));
      await steps(tester, 2);
    }
    expect(find.textContaining('Turn sharp left onto Iqbal Park Parking Lot'), findsOneWidget);

    source.emit(at(lahore.points.last));
    await steps(tester);
    expect(find.text(l.navArrivedTitle), findsOneWidget);
    expect(find.text(l.navArrivedBody('Badshahi Mosque')), findsOneWidget);
    expect(awake.on, isFalse);
    await tester.tap(find.text(l.done));
    await steps(tester);
    expect(find.byType(NavigationScreen), findsNothing);
  });

  testWidgets('Urdu: directions in Urdu, arrival time in 24-hour form (no stray "p")', (tester) async {
    source = FakeTrackSource();
    routing = FakeRouting();
    awake = FakeScreenAwake();
    speaker = FakeSpeaker();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(
      locale: const Locale('ur'),
      overrides: [
        locationSourceProvider.overrideWithValue(source),
        routingServiceProvider.overrideWithValue(routing),
        screenAwakeProvider.overrideWithValue(awake),
        speakerProvider.overrideWithValue(speaker),
        navigationControllerProvider.overrideWith(() => NavigationController(clock: () => now)),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
      ],
      home: NavigationScreen(destination: lahore.points.last, label: 'Badshahi Mosque'),
    ));
    await steps(tester);
    source.emit(at(lahore.points.first));
    await steps(tester);
    final ur = await AppLocalizations.delegate.load(const Locale('ur'));
    await tester.tap(find.text(ur.navStart));
    await steps(tester);
    expect(find.text(ur.navTurnLeft), findsOneWidget);
    expect(find.text('950 میٹر'), findsOneWidget);
    final eta = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.contains('کلومیٹر ·'));
    expect(eta, matches(RegExp(r'\d{2}:\d{2} تک پہنچیں')));
    expect(eta.contains(' p'), isFalse);
  });

  testWidgets('End asks first; "Keep going" continues, End stops and closes', (tester) async {
    await toReady(tester);
    await tester.tap(find.text(l.navStart));
    await steps(tester);
    await tester.tap(find.text(l.navEnd));
    await steps(tester);
    expect(find.text(l.navEndTitle), findsOneWidget);
    await tester.tap(find.text(l.navKeepGoing));
    await steps(tester);
    expect(find.byType(NavInstructionCard), findsOneWidget);

    await tester.tap(find.text(l.navEnd));
    await steps(tester);
    await tester.tap(find.text(l.navEnd).last);
    await steps(tester);
    expect(find.byType(NavigationScreen), findsNothing);
    expect(awake.on, isFalse);
    expect(source.listening, isFalse);
  });

  testWidgets('no destination: explained, nothing started, only Close offered', (tester) async {
    await open(tester, destination: null);
    expect(find.text(l.navErrNoDestination), findsOneWidget);
    expect(find.text(l.tryAgain), findsNothing);
    expect(source.watches, isEmpty);
    await tester.tap(find.text(l.close).last);
    await steps(tester);
    expect(find.byType(NavigationScreen), findsNothing);
  });

  testWidgets('location blocked: explained, with Open settings', (tester) async {
    await open(tester, destination: lahore.points.last, configure: () => source.access = LocationAccess.deniedForever);
    expect(find.text(l.navErrBlocked), findsOneWidget);
    expect(find.text(l.liveOpenSettings), findsOneWidget);
    expect(routing.calls, isEmpty);
  });

  testWidgets('no road route: explained; Try again works once the problem is gone', (tester) async {
    await open(tester, destination: lahore.points.last, configure: () => routing.failure = RoutingFailure.noRoute);
    source.emit(at(lahore.points.first));
    await steps(tester);
    expect(find.text(l.navErrNoRoute), findsOneWidget);
    routing.failure = null;
    await tester.tap(find.text(l.tryAgain));
    await steps(tester);
    expect(find.text(l.navStart), findsOneWidget);
  });

  testWidgets('voice: the first instruction is spoken on Start; the mute button silences it and is remembered for the session', (tester) async {
    await toReady(tester);
    await tester.tap(find.text(l.navStart));
    await steps(tester);
    expect(speaker.spoken, ['In 950 metres, turn left']);
    await tester.tap(find.byTooltip(l.navMute));
    await steps(tester);
    expect(find.byTooltip(l.navUnmute), findsOneWidget);
    expect(speaker.stops, greaterThan(0));
    for (var along = 100.0; along <= 900; along += 100) {
      source.emit(at(line.pointAt(along)));
      await steps(tester, 2);
    }
    expect(speaker.spoken, hasLength(1), reason: 'muted');
  });

  testWidgets('leaving the route shows "finding a new route", then guides on the new one', (tester) async {
    await toReady(tester);
    await tester.tap(find.text(l.navStart));
    await steps(tester);
    LatLng aside(double along) {
      final p = line.pointAt(along);
      return const Distance().offset(p, 150, const Distance().bearing(p, line.pointAt(along + 20)) + 90);
    }

    routing.failure = RoutingFailure.unavailable;
    for (var i = 0; i < 5; i++) {
      now = now.add(const Duration(seconds: 2));
      source.emit(at(aside(200.0 + i * 30)));
      await steps(tester, 2);
    }
    expect(find.text(l.navRerouteFailed), findsOneWidget, reason: 'service trouble: keep going or try again');
    routing.failure = null;
    await tester.tap(find.text(l.tryAgain));
    await steps(tester);
    expect(find.text(l.navRerouteFailed), findsNothing);
    expect(find.byType(NavInstructionCard), findsOneWidget);
    expect(speaker.spoken, contains('New route found.'));
  });
}

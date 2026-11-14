import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/announcement_planner.dart';
import 'package:skill_bridge/features/navigation/domain/navigation_engine.dart';
import 'package:skill_bridge/features/navigation/domain/off_route_detector.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/navigation_controller.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/routing_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/screen_awake.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/voice_guidance.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_location.dart';
import '../helpers/fake_navigation.dart';

void main() {
  final t0 = DateTime(2026, 11, 14, 10);
  final lahore = recordedRoute('lahore_route').primary;
  final line = RouteLine(lahore.points);

  group('OffRouteDetector', () {
    test('one far fix is drifting, not off route; it takes 3 fixes and 5 seconds', () {
      final d = OffRouteDetector();
      expect(d.update(distanceFromRoute: 90, accuracy: 8, at: t0), RouteAdherence.drifting);
      expect(d.update(distanceFromRoute: 90, accuracy: 8, at: t0.add(const Duration(seconds: 1))), RouteAdherence.drifting);
      expect(d.update(distanceFromRoute: 90, accuracy: 8, at: t0.add(const Duration(seconds: 2))), RouteAdherence.drifting,
          reason: '3 fixes but only 2 s');
      expect(d.update(distanceFromRoute: 90, accuracy: 8, at: t0.add(const Duration(seconds: 5))), RouteAdherence.offRoute);
    });

    test('a rough fix gets a wider allowance; too-rough fixes and lost signal are ignored', () {
      final d = OffRouteDetector();
      expect(d.limitFor(5), 35);
      expect(d.limitFor(30), 55);
      expect(d.limitFor(200), 80, reason: 'capped');
      for (var i = 0; i < 6; i++) {
        d.update(distanceFromRoute: 70, accuracy: 120, at: t0.add(Duration(seconds: i * 2)));
        d.update(distanceFromRoute: 70, accuracy: 8, at: t0.add(Duration(seconds: i * 2 + 1)), signalLost: true);
      }
      expect(d.state, RouteAdherence.onRoute, reason: 'nothing usable to judge by');
      // 50 m off with a ±30 m fix is within the 55 m allowance.
      expect(d.update(distanceFromRoute: 50, accuracy: 30, at: t0), RouteAdherence.onRoute);
    });

    test('coming back well inside clears it; hovering at the edge doesn\'t flap', () {
      final d = OffRouteDetector();
      for (var i = 0; i <= 5; i++) {
        d.update(distanceFromRoute: 60, accuracy: 5, at: t0.add(Duration(seconds: i * 2)));
      }
      expect(d.state, RouteAdherence.offRoute);
      expect(d.update(distanceFromRoute: 30, accuracy: 5, at: t0.add(const Duration(seconds: 20))), RouteAdherence.offRoute,
          reason: 'between 70 % and 100 % of the limit: unchanged');
      expect(d.update(distanceFromRoute: 10, accuracy: 5, at: t0.add(const Duration(seconds: 21))), RouteAdherence.onRoute);
    });

    test('going back along the route the wrong way counts as off route', () {
      final d = OffRouteDetector();
      for (var i = 0; i <= 5; i++) {
        d.update(distanceFromRoute: 3, accuracy: 5, progressDrop: 120, at: t0.add(Duration(seconds: i * 2)));
      }
      expect(d.state, RouteAdherence.offRoute);
    });
  });

  group('AnnouncementPlanner', () {
    List<Announcement> drive({double step = 10, double? speed}) {
      final engine = NavigationEngine(lahore);
      final planner = AnnouncementPlanner();
      final out = <Announcement>[];
      for (var along = 0.0; along <= line.length + 10; along += step) {
        final p = engine.update(line.pointAt(along), now: t0);
        final a = planner.next(p, routeVersion: 0, speed: speed);
        if (a != null) out.add(a);
        if (p.arrived) {
          // Further positions after arrival say nothing more.
          final again = planner.next(engine.update(line.pointAt(line.length), now: t0), routeVersion: 0);
          expect(again, isNull);
          break;
        }
      }
      return out;
    }

    test('a drive: start, then each maneuver near and at the turn, early only for the long first stretch, approaching and arrived once', () {
      final said = drive();
      expect(said.first.kind, AnnouncementKind.start);
      expect(said.first.stepIndex, 1);
      final keys = said.map((a) => '${a.kind.name}:${a.stepIndex}').toList();
      expect(keys.toSet().length, keys.length, reason: 'nothing said twice');
      expect(keys, contains('early:1'), reason: 'step 0 is 949 m long');
      expect(keys.where((k) => k.startsWith('early:')), hasLength(lessThanOrEqualTo(3)));
      for (final i in [1, 2, 3, 4, 5, 6]) {
        expect(keys, contains('near:$i'), reason: 'maneuver $i');
        expect(keys, contains('now:$i'), reason: 'maneuver $i');
      }
      // Step 7 comes 8 m after step 6: said with it ("…, then turn right"),
      // so it gets no separate early/near warning.
      expect(keys, isNot(contains('near:7')));
      expect(keys, isNot(contains('early:7')));
      expect(keys.where((k) => k.startsWith('approaching')), hasLength(1));
      expect(said.last.kind, AnnouncementKind.arrived);
    });

    test('first seen already close to a turn: only the closest band is said (nothing stacked)', () {
      final engine = NavigationEngine(lahore);
      final planner = AnnouncementPlanner();
      final turn = engine.stepStartAt(1);
      expect(planner.next(engine.update(line.pointAt(turn - 100), now: t0), routeVersion: 0)!.kind, AnnouncementKind.start);
      expect(planner.next(engine.update(line.pointAt(turn - 90), now: t0), routeVersion: 0), isNull, reason: 'near already covered by start');
      expect(planner.next(engine.update(line.pointAt(turn - 20), now: t0), routeVersion: 0)!.kind, AnnouncementKind.now);
    });

    test('well off the route nothing about it is said (not even "approaching"); back on it, guidance resumes', () {
      final engine = NavigationEngine(lahore);
      final planner = AnnouncementPlanner();
      expect(planner.next(engine.update(line.pointAt(100), now: t0), routeVersion: 0)!.kind, AnnouncementKind.start);
      // Beside the very end of the route, 120 m off it.
      final end = line.pointAt(line.length - 40);
      final off = const Distance().offset(end, 120, const Distance().bearing(end, line.pointAt(line.length)) + 90);
      final p = engine.update(off, now: t0);
      expect(p.distanceFromRoute, greaterThan(50));
      expect(planner.next(p, routeVersion: 0), isNull);
      final turn = engine.stepStartAt(1);
      final engine2 = NavigationEngine(lahore);
      final planner2 = AnnouncementPlanner();
      planner2.next(engine2.update(line.pointAt(0), now: t0), routeVersion: 0);
      final aside = const Distance().offset(line.pointAt(turn - 100), 120, 0);
      expect(planner2.next(engine2.update(aside, now: t0), routeVersion: 0), isNull, reason: 'off route near a turn');
      expect(planner2.next(engine2.update(line.pointAt(turn - 90), now: t0), routeVersion: 0)!.kind, AnnouncementKind.near,
          reason: 'said once back on the route');
    });

    test('faster driving warns earlier (about 10 s ahead)', () {
      final p = AnnouncementPlanner();
      expect(p.nearAt(null), 150);
      expect(p.nearAt(5), 80);
      expect(p.nearAt(20), 200);
      expect(p.nearAt(40), 250);
    });

    test('a new route is announced once and starts fresh', () {
      final engine = NavigationEngine(lahore);
      final planner = AnnouncementPlanner();
      final p = engine.update(line.pointAt(100), now: t0);
      expect(planner.next(p, routeVersion: 0)!.kind, AnnouncementKind.start);
      expect(planner.next(p, routeVersion: 1)!.kind, AnnouncementKind.rerouted);
      expect(planner.next(p, routeVersion: 1), isNull);
    });
  });

  group('spoken sentences', () {
    late AppLocalizations en;
    late AppLocalizations ur;
    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      ur = await AppLocalizations.delegate.load(const Locale('ur'));
    });
    final s = NavState(status: NavStatus.navigating, result: recordedRoute('lahore_route'));

    test('distances in words, instructions mid-sentence, a close next turn said together', () {
      expect(spokenDistance(en, 497), '500 metres');
      expect(spokenDistance(en, 1460), '1.5 kilometres');
      expect(spokenDistance(ur, 140), '140 میٹر');
      expect(sentenceFor(en, const Announcement(AnnouncementKind.early, stepIndex: 1, distance: 497), s), 'In 500 metres, turn left');
      expect(sentenceFor(en, const Announcement(AnnouncementKind.now, stepIndex: 1, distance: 20), s), 'Turn left');
      // Step 6 (8 m) is followed right away by step 7.
      expect(sentenceFor(en, const Announcement(AnnouncementKind.near, stepIndex: 6, distance: 120), s),
          'In 120 metres, turn sharp left, then turn right');
      expect(sentenceFor(en, const Announcement(AnnouncementKind.approaching), s), 'You are approaching your destination');
      expect(sentenceFor(en, const Announcement(AnnouncementKind.arrived), s), 'You have arrived');
      expect(sentenceFor(ur, const Announcement(AnnouncementKind.early, stepIndex: 1, distance: 497), s), '500 میٹر بعد، بائیں مڑیں');
      expect(sentenceFor(ur, const Announcement(AnnouncementKind.rerouted), s), 'نیا راستہ مل گیا۔');
    });
  });

  group('rerouting and voice in a session', () {
    late FakeTrackSource source;
    late FakeRouting routing;
    late FakeSpeaker speaker;
    late ProviderContainer c;
    late DateTime now;
    var online = true;
    var disposed = false;

    GeoFix at(LatLng p, {double accuracy = 6}) => GeoFix(lat: p.latitude, lng: p.longitude, accuracy: accuracy);
    NavigationController ctl() => c.read(navigationControllerProvider.notifier);
    NavState st() => c.read(navigationControllerProvider);

    void build({Set<String>? voices, String language = 'en'}) {
      source = FakeTrackSource();
      routing = FakeRouting();
      speaker = FakeSpeaker(voices: voices);
      now = t0;
      disposed = false;
      c = ProviderContainer(overrides: [
        locationSourceProvider.overrideWithValue(source),
        routingServiceProvider.overrideWithValue(routing),
        screenAwakeProvider.overrideWithValue(FakeScreenAwake()),
        speakerProvider.overrideWithValue(speaker),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(online)),
        navigationControllerProvider.overrideWith(() => NavigationController(clock: () => now)),
      ]);
      c.listen(navigationControllerProvider, (_, _) {});
      c.listen(navigationVoiceProvider, (_, _) {});
      c.listen(connectivityStatusProvider, (_, _) {});
      c.read(navigationVoiceProvider.notifier).setLanguage(language);
    }

    void done() {
      c.dispose();
      disposed = true;
    }

    setUp(() => online = true);
    tearDown(() {
      if (!disposed) c.dispose();
    });

    Future<void> startGuiding(WidgetTester tester) async {
      final f = ctl().prepare(lahore.points.last);
      await tester.pump();
      source.emit(at(lahore.points.first));
      await tester.pump();
      await f;
      await ctl().start();
      await tester.pump();
      await tester.pump();
    }

    /// Steps the clock and feeds a fix.
    Future<void> feed(WidgetTester tester, LatLng p, {double accuracy = 6, int seconds = 2}) async {
      now = now.add(Duration(seconds: seconds));
      source.emit(at(p, accuracy: accuracy));
      await tester.pump();
      await tester.pump();
    }

    LatLng aside(double along, double metres) {
      final p = line.pointAt(along);
      return const Distance().offset(p, metres, const Distance().bearing(p, line.pointAt(along + 20)) + 90);
    }

    testWidgets('leaving the route: confirmed after a few fixes, a new route from the latest position, announced once', (tester) async {
      build();
      await startGuiding(tester);
      expect(speaker.spoken, isNotEmpty, reason: 'the first instruction is spoken on start');
      expect(speaker.spoken.first, 'In 950 metres, turn left');

      await feed(tester, line.pointAt(200));
      await feed(tester, aside(260, 120));
      expect(st().status, NavStatus.navigating, reason: 'one far fix is not enough');
      await feed(tester, aside(300, 140));
      await feed(tester, aside(340, 160));
      await feed(tester, aside(380, 180));
      expect(routing.calls, hasLength(2), reason: 'initial route + one reroute');
      expect(routing.calls.last.$1, aside(380, 180), reason: 'from the latest position');
      await tester.pump();
      expect(st().status, NavStatus.navigating);
      expect(st().routeVersion, 1);
      expect(st().rerouteCount, 1);
      expect(speaker.spoken.where((t) => t == 'New route found.'), hasLength(1));

      // Still off the (recorded, fake) route: no new request within the cooldown.
      await feed(tester, aside(420, 200));
      await feed(tester, aside(460, 210));
      await feed(tester, aside(500, 220));
      expect(routing.calls, hasLength(2), reason: '15 s cooldown');
      done();
    });

    testWidgets('rough fixes and a lost signal never trigger a reroute', (tester) async {
      build();
      await startGuiding(tester);
      for (var i = 0; i < 6; i++) {
        await feed(tester, aside(200.0 + i * 20, 150), accuracy: 120);
      }
      expect(routing.calls, hasLength(1));
      expect(st().status, NavStatus.navigating);
      done();
    });

    testWidgets('a failed reroute keeps guiding on the old route, says why, and clears once back on route', (tester) async {
      online = false;
      build();
      await startGuiding(tester);
      routing.failure = RoutingFailure.network;
      for (var i = 0; i < 5; i++) {
        await feed(tester, aside(200.0 + i * 30, 150));
      }
      expect(st().status, NavStatus.navigating);
      expect(st().rerouteProblem, NavError.offline);
      expect(st().routeVersion, 0);
      await feed(tester, line.pointAt(400));
      expect(st().rerouteProblem, isNull);

      routing.failure = null;
      // The 15 s cooldown since the failed attempt has to pass first.
      // (The same stretch as before: this route circles Iqbal Park, so points
      // beside other parts of it can lie close to a later part of the route.)
      for (var i = 0; i < 9; i++) {
        await feed(tester, aside(200.0 + (i % 5) * 30, 150));
      }
      expect(st().routeVersion, 1, reason: 'retried after the cooldown and succeeded');
      expect(routing.calls, hasLength(3), reason: 'initial, failed, successful');
      done();
    });

    testWidgets('Try again asks for a new route at once', (tester) async {
      build();
      await startGuiding(tester);
      await feed(tester, line.pointAt(150));
      await ctl().rerouteNow();
      await tester.pump();
      expect(routing.calls, hasLength(2));
      expect(st().routeVersion, 1);
      done();
    });

    testWidgets('muted: nothing is spoken (but tracked); unmuting says the next instruction once', (tester) async {
      build();
      await c.read(voiceMutedProvider.notifier).setMuted(true);
      await startGuiding(tester);
      await feed(tester, line.pointAt(450));
      expect(speaker.spoken, isEmpty);
      expect(c.read(navigationVoiceProvider).lastSpoken, isNotNull);

      await c.read(voiceMutedProvider.notifier).setMuted(false);
      await tester.pump();
      await tester.pump();
      expect(speaker.spoken, hasLength(1));
      expect(speaker.spoken.single, startsWith('In '));
      done();
    });

    testWidgets('Urdu screen: Urdu voice when installed', (tester) async {
      build(language: 'ur');
      await startGuiding(tester);
      expect(speaker.language, 'ur-PK');
      expect(speaker.spoken.first, '950 میٹر بعد، بائیں مڑیں');
      expect(c.read(navigationVoiceProvider).notice, VoiceNotice.none);
      done();
    });

    testWidgets('no Urdu voice: English speech with a notice; no voice at all: on-screen only', (tester) async {
      build(language: 'ur', voices: {'en-US'});
      await startGuiding(tester);
      expect(speaker.language, 'en-US');
      expect(speaker.spoken.first, 'In 950 metres, turn left');
      expect(c.read(navigationVoiceProvider).notice, VoiceNotice.englishFallback);
      c.dispose();

      build(voices: {});
      await startGuiding(tester);
      await tester.pump(const Duration(seconds: 2)); // the second try
      await tester.pump();
      expect(speaker.spoken, isEmpty);
      expect(c.read(navigationVoiceProvider).notice, VoiceNotice.unavailable);
      done();
    });

    testWidgets('voices that load late (browsers) are found on the second try; nothing is lost', (tester) async {
      build(voices: {});
      await startGuiding(tester);
      speaker.voices.add('en-GB'); // the browser finished loading its voices
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(speaker.language, 'en-GB');
      expect(speaker.spoken, ['In 950 metres, turn left']);
      expect(c.read(navigationVoiceProvider).notice, VoiceNotice.none);
      done();
    });

    testWidgets('ending stops speech; nothing is said when not navigating', (tester) async {
      build();
      final f = ctl().prepare(lahore.points.last);
      await tester.pump();
      source.emit(at(lahore.points.first));
      await tester.pump();
      await f;
      await tester.pump();
      expect(speaker.spoken, isEmpty, reason: 'route chosen but not started');
      await ctl().start();
      await tester.pump();
      ctl().end();
      await tester.pump();
      expect(speaker.stops, greaterThan(0));
      done();
    });
  });
}

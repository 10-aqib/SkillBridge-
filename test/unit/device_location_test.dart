import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/location/device_location_tracker.dart';

import '../helpers/fake_location.dart';

Position _pos({
  double lat = 31.52,
  double lng = 74.35,
  double accuracy = 8,
  double heading = 0,
  double headingAccuracy = 0,
  double speed = 0,
  double speedAccuracy = 0,
  DateTime? at,
}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: at ?? DateTime(2026, 11, 14, 10),
      accuracy: accuracy,
      altitude: 210,
      altitudeAccuracy: 3,
      heading: heading,
      headingAccuracy: headingAccuracy,
      speed: speed,
      speedAccuracy: speedAccuracy,
    );

GeoFix _fix(double lat, double lng, {double acc = 8, DateTime? at}) => GeoFix(lat: lat, lng: lng, accuracy: acc, takenAt: at);

void main() {
  group('GeoFix', () {
    test('invalid values from the platform become "unknown", not numbers', () {
      // iOS reports -1 for unknown heading and speed.
      final ios = GeoFix.fromPosition(_pos(heading: -1, speed: -1, speedAccuracy: -1));
      expect(ios.heading, isNull);
      expect(ios.speed, isNull);
      expect(ios.hasReliableHeading, isFalse);

      // Many Android devices say "0°, accuracy 0" when standing still.
      final still = GeoFix.fromPosition(_pos(heading: 0, headingAccuracy: 0, speed: 0.2));
      expect(still.heading, isNull);

      final driving = GeoFix.fromPosition(_pos(heading: 92.5, headingAccuracy: 10, speed: 9.7, speedAccuracy: 0.5));
      expect(driving.heading, 92.5);
      expect(driving.speed, 9.7);
      expect(driving.hasReliableHeading, isTrue);
      expect(driving.timestamp, DateTime(2026, 11, 14, 10));
      expect(driving.point, const GeoCoord(31.52, 74.35));
    });

    test('heading counts only while moving, and only when it is precise enough', () {
      expect(const GeoFix(lat: 1, lng: 1, accuracy: 5, heading: 40, speed: 0.5).hasReliableHeading, isFalse, reason: 'walking pace noise');
      expect(const GeoFix(lat: 1, lng: 1, accuracy: 5, heading: 40, speed: 5, headingAccuracy: 90).hasReliableHeading, isFalse);
      expect(const GeoFix(lat: 1, lng: 1, accuracy: 5, heading: 40, speed: 5).hasReliableHeading, isTrue);
    });

    test('impossible coordinates are not valid', () {
      expect(_fix(31.5, 74.3).isValid, isTrue);
      for (final f in [_fix(double.nan, 74.3), _fix(91, 74.3), _fix(31.5, 181), _fix(0, 0), _fix(31.5, 74.3, acc: -1), _fix(31.5, 74.3, acc: double.infinity)]) {
        expect(f.isValid, isFalse, reason: '$f');
      }
    });

    test('bearing between points', () {
      expect(bearingBetween(const GeoCoord(31.5, 74.3), const GeoCoord(31.6, 74.3)), closeTo(0, 0.01));
      expect(bearingBetween(const GeoCoord(31.5, 74.3), const GeoCoord(31.5, 74.4)), closeTo(90, 0.1));
      expect(bearingBetween(const GeoCoord(31.5, 74.3), const GeoCoord(31.4, 74.3)), closeTo(180, 0.01));
    });
  });

  group('LocationProfile', () {
    test('Android: navigation asks for about one fix a second, sharing and maps far fewer', () {
      final nav = LocationProfile.navigation.settings(web: false, platform: TargetPlatform.android) as AndroidSettings;
      expect(nav.accuracy, LocationAccuracy.bestForNavigation);
      expect(nav.intervalDuration, const Duration(seconds: 1));
      expect(nav.distanceFilter, 5);
      expect(nav.foregroundNotificationConfig, isNull, reason: 'no background service');
      final display = LocationProfile.display.settings(web: false, platform: TargetPlatform.android) as AndroidSettings;
      expect(display.intervalDuration, const Duration(seconds: 5));
      expect(display.distanceFilter, 15);
    });

    test('iOS: never background updates; navigation uses the driving mode and is never paused', () {
      for (final p in LocationProfile.values) {
        final s = p.settings(web: false, platform: TargetPlatform.iOS) as AppleSettings;
        expect(s.allowBackgroundLocationUpdates, isFalse, reason: p.name);
        expect(s.showBackgroundLocationIndicator, isFalse);
      }
      final nav = LocationProfile.navigation.settings(web: false, platform: TargetPlatform.iOS) as AppleSettings;
      expect(nav.activityType, ActivityType.automotiveNavigation);
      expect(nav.pauseLocationUpdatesAutomatically, isFalse);
      final share = LocationProfile.sharing.settings(web: false, platform: TargetPlatform.iOS) as AppleSettings;
      expect(share.pauseLocationUpdatesAutomatically, isTrue, reason: 'saves battery when parked');
    });

    test('web refuses cached browser positions', () {
      final w = LocationProfile.sharing.settings(web: true) as WebSettings;
      expect(w.maximumAge, Duration.zero);
    });

    test('navigation notices a lost signal quickly; sharing keeps its 60 s heartbeat window', () {
      expect(LocationProfile.navigation.staleAfter, lessThan(const Duration(seconds: 15)));
      expect(LocationProfile.sharing.staleAfter, const Duration(seconds: 60));
    });
  });

  group('checkFix', () {
    final now = DateTime(2026, 11, 14, 10, 0, 30);
    const p = LocationProfile.navigation;

    test('a normal next fix is accepted', () {
      final a = _fix(31.5200, 74.3500, at: now.subtract(const Duration(seconds: 1)));
      final b = _fix(31.5201, 74.3501, at: now);
      expect(checkFix(b, previous: a, now: now, profile: p), isNull);
    });

    test('invalid, cached-long-ago and out-of-order fixes are dropped', () {
      final a = _fix(31.52, 74.35, at: now);
      expect(checkFix(_fix(double.nan, 74.35, at: now), now: now, profile: p), FixRejection.invalid);
      expect(checkFix(_fix(31.52, 74.35, at: now.subtract(const Duration(minutes: 3))), now: now, profile: p), FixRejection.tooOld);
      expect(checkFix(_fix(31.52, 74.35, at: now.subtract(const Duration(seconds: 2))), previous: a, now: now, profile: p), FixRejection.outOfOrder);
    });

    test('a jump faster than 250 km/h is a glitch, unless the error circles explain it', () {
      final a = _fix(31.5200, 74.3500, at: now.subtract(const Duration(seconds: 1)));
      // ~1.1 km in one second.
      expect(checkFix(_fix(31.5300, 74.3500, at: now), previous: a, now: now, profile: p), FixRejection.impossibleJump);
      // ~110 m in one second, but each fix is only ±80 m accurate: allowed.
      final rough = _fix(31.5200, 74.3500, acc: 80, at: now.subtract(const Duration(seconds: 1)));
      expect(checkFix(_fix(31.5210, 74.3500, acc: 80, at: now), previous: rough, now: now, profile: p), isNull);
    });
  });

  group('DeviceLocationTracker', () {
    late FakeTrackSource source;
    late ProviderContainer container;

    var disposed = false;
    setUp(() {
      source = FakeTrackSource();
      disposed = false;
      container = ProviderContainer(overrides: [locationSourceProvider.overrideWithValue(source)]);
    });
    // Tests dispose inside their body (fake timers must be gone before the
    // test ends); this catches any that don't.
    tearDown(() {
      if (!disposed) container.dispose();
    });
    void done() {
      container.dispose();
      disposed = true;
    }

    DeviceLocationTracker tracker() => container.read(deviceLocationProvider.notifier);
    DeviceLocationState st() => container.read(deviceLocationProvider);
    void keepAlive() => container.listen(deviceLocationProvider, (_, _) {});

    for (final (access, status) in [
      (LocationAccess.denied, DeviceLocationStatus.permissionDenied),
      (LocationAccess.deniedForever, DeviceLocationStatus.permissionBlocked),
      (LocationAccess.serviceOff, DeviceLocationStatus.serviceOff),
      (LocationAccess.unavailable, DeviceLocationStatus.unavailable),
    ]) {
      testWidgets('${access.name}: reported, and GPS is never started', (tester) async {
        keepAlive();
        source.access = access;
        expect(await tracker().start(LocationProfile.display), status);
        expect(source.watches, isEmpty);
        expect(st().currentFix, isNull);
        done();
      });
    }

    testWidgets('tracks with the asked profile, shows fixes, and reports approximate-only location', (tester) async {
      keepAlive();
      source.precise = false;
      expect(await tracker().start(LocationProfile.navigation), DeviceLocationStatus.active);
      expect(source.watches, [LocationProfile.navigation]);
      expect(st().precise, isFalse);
      expect(st().signalLost, isTrue, reason: 'no fix yet');
      expect(st().currentFix, isNull);

      source.emit(const GeoFix(lat: 31.52, lng: 74.35, accuracy: 6, heading: 80, speed: 8));
      await tester.pump();
      expect(st().currentFix?.lat, 31.52);
      expect(st().signalLost, isFalse);
      done();
    });

    testWidgets('no fix within the profile window marks the signal lost; a new fix restores it', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.navigation);
      source.emit(const GeoFix(lat: 31.52, lng: 74.35, accuracy: 6));
      await tester.pump();
      expect(st().currentFix, isNotNull);

      await tester.pump(LocationProfile.navigation.staleAfter + const Duration(seconds: 1));
      expect(st().signalLost, isTrue);
      expect(st().currentFix, isNull, reason: 'an old position is never shown as current');
      expect(st().fix, isNotNull, reason: 'kept as last known');

      source.emit(const GeoFix(lat: 31.5201, lng: 74.3501, accuracy: 6));
      await tester.pump();
      expect(st().signalLost, isFalse);
      done();
    });

    testWidgets('dropped fixes never replace the current one', (tester) async {
      keepAlive();
      final t0 = DateTime.now();
      await tracker().start(LocationProfile.navigation);
      source.emit(_fix(31.5200, 74.3500, at: t0));
      await tester.pump();
      source.emit(_fix(31.6000, 74.3500, at: t0.add(const Duration(seconds: 1)))); // 9 km in 1 s
      source.emit(_fix(31.5201, 74.3500, at: t0.subtract(const Duration(seconds: 5)))); // older
      source.emit(_fix(double.nan, 74.35));
      await tester.pump();
      expect(st().fix!.lat, 31.5200);
      expect(tracker().rejected, 3);
      done();
    });

    testWidgets('GPS switched off and on while tracking', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.display);
      source.emit(const GeoFix(lat: 31.52, lng: 74.35, accuracy: 6));
      await tester.pump();

      source.service.add(false);
      await tester.pump();
      expect(st().status, DeviceLocationStatus.serviceOff);
      expect(st().currentFix, isNull);
      expect(source.listening, isFalse);

      source.service.add(true);
      await tester.pump();
      await tester.pump();
      expect(st().status, DeviceLocationStatus.active);
      expect(source.watches, hasLength(2));
      expect(source.listening, isTrue);
      done();
    });

    testWidgets('a "location services disabled" stream error is GPS off', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.display);
      source.live!.addError(const LocationServiceDisabledException());
      await tester.pump();
      expect(st().status, DeviceLocationStatus.serviceOff);
      done();
    });

    testWidgets('in the background GPS stops; back in the foreground it resumes', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.navigation);
      source.emit(const GeoFix(lat: 31.52, lng: 74.35, accuracy: 6));
      await tester.pump();

      tracker().appHidden();
      await tester.pump();
      expect(st().paused, isTrue);
      expect(source.listening, isFalse);
      expect(st().currentFix, isNull);

      tracker().appShown();
      await tester.pump();
      await tester.pump();
      expect(st().paused, isFalse);
      expect(source.listening, isTrue);
      expect(source.watches, [LocationProfile.navigation, LocationProfile.navigation]);
      done();
    });

    testWidgets('if the platform ends the stream, tracking restarts once after a short wait', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.display);
      await source.live!.close();
      await tester.pump();
      expect(source.watches, hasLength(1));
      await tester.pump(const Duration(seconds: 4));
      expect(source.watches, hasLength(2));
      done();
    });

    testWidgets('stop() and the last screen leaving both stop GPS', (tester) async {
      final sub = container.listen(deviceLocationProvider, (_, _) {});
      await tracker().start(LocationProfile.display);
      tracker().stop();
      expect(source.listening, isFalse);
      expect(st().status, DeviceLocationStatus.idle);

      await tracker().start(LocationProfile.display);
      expect(source.listening, isTrue);
      sub.close();
      // Riverpod disposes unused providers on its own schedule.
      final disposal = container.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await disposal;
      await tester.pump();
      expect(source.listening, isFalse, reason: 'auto-dispose stops tracking');
      done();
    });

    testWidgets('shared (phase 8): one stream for navigation and sharing, the strongest profile wins, GPS stops with the last release', (tester) async {
      keepAlive();
      await tracker().request('sharing', LocationProfile.sharing);
      expect(source.watches, [LocationProfile.sharing]);
      await tracker().request('navigation', LocationProfile.navigation);
      expect(source.watches.last, LocationProfile.navigation, reason: 'navigation needs more');
      expect(source.listening, isTrue);

      tracker().release('navigation');
      await tester.pump();
      expect(source.watches.last, LocationProfile.sharing, reason: 'back to what sharing needs');
      expect(source.listening, isTrue, reason: 'ending navigation must not stop sharing');

      tracker().release('sharing');
      await tester.pump();
      expect(source.listening, isFalse);
      expect(st().status, DeviceLocationStatus.idle);
      done();
    });

    testWidgets('standing still (no updates) is not a lost signal: a fresh one-shot fix keeps it current', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.navigation);
      source.emit(const GeoFix(lat: 31.52, lng: 74.35, accuracy: 6));
      await tester.pump();
      source.oneShot = GeoFix(lat: 31.52, lng: 74.35, accuracy: 6, takenAt: DateTime.now());
      for (var i = 0; i < 3; i++) {
        await tester.pump(LocationProfile.navigation.staleAfter + const Duration(seconds: 1));
        await tester.pump();
        expect(st().signalLost, isFalse, reason: 'stopped at a light, ${i + 1}');
      }
      expect(source.oneShotRequests, greaterThanOrEqualTo(3));
      done();
    });

    testWidgets('a real loss (the one-shot fix fails too) is lost; a later fix restores it', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.navigation);
      source.emit(const GeoFix(lat: 31.52, lng: 74.35, accuracy: 6));
      await tester.pump();
      await tester.pump(LocationProfile.navigation.staleAfter + const Duration(seconds: 1));
      await tester.pump();
      expect(st().signalLost, isTrue);
      expect(st().currentFix, isNull);
      // Asks again later; the signal is back.
      source.oneShot = GeoFix(lat: 31.5201, lng: 74.3501, accuracy: 6, takenAt: DateTime.now());
      await tester.pump(LocationProfile.navigation.staleAfter + const Duration(seconds: 1));
      await tester.pump();
      expect(st().signalLost, isFalse);
      done();
    });

    testWidgets('asking for a different profile switches the stream', (tester) async {
      keepAlive();
      await tracker().start(LocationProfile.display);
      await tracker().start(LocationProfile.display);
      expect(source.watches, hasLength(1), reason: 'same profile: nothing restarts');
      await tracker().start(LocationProfile.navigation);
      expect(source.watches, [LocationProfile.display, LocationProfile.navigation]);
      expect(source.cancels, 1);
      done();
    });
  });
}

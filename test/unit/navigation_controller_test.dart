import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/location/device_location_tracker.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/navigation_controller.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/routing_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/screen_awake.dart';

import '../helpers/fake_location.dart';
import '../helpers/fake_navigation.dart';

void main() {
  late FakeTrackSource source;
  late FakeRouting routing;
  late FakeScreenAwake awake;
  late ProviderContainer c;
  var online = true;
  var disposed = false;

  final lahore = recordedRoute('lahore_route').primary;
  final line = RouteLine(lahore.points);
  final start = lahore.points.first;
  final destination = lahore.points.last;
  GeoFix at(LatLng p) => GeoFix(lat: p.latitude, lng: p.longitude, accuracy: 6);

  void setUpContainer() {
    source = FakeTrackSource();
    routing = FakeRouting();
    awake = FakeScreenAwake();
    disposed = false;
    c = ProviderContainer(overrides: [
      locationSourceProvider.overrideWithValue(source),
      routingServiceProvider.overrideWithValue(routing),
      screenAwakeProvider.overrideWithValue(awake),
      connectivityStatusProvider.overrideWith((ref) => Stream.value(online)),
    ]);
    c.listen(navigationControllerProvider, (_, _) {});
    c.listen(connectivityStatusProvider, (_, _) {});
  }

  setUp(() {
    online = true;
    setUpContainer();
  });
  tearDown(() {
    if (!disposed) c.dispose();
  });
  void done() {
    c.dispose();
    disposed = true;
  }

  NavigationController ctl() => c.read(navigationControllerProvider.notifier);
  NavState st() => c.read(navigationControllerProvider);

  /// prepare() up to "ready", feeding the first fix at the route start.
  Future<void> ready(WidgetTester tester) async {
    final f = ctl().prepare(destination, label: 'Badshahi Mosque');
    await tester.pump();
    expect(st().status, NavStatus.locating);
    source.emit(at(start));
    await tester.pump();
    await f;
    await tester.pump();
  }

  testWidgets('no destination: an error, and GPS is never started', (tester) async {
    await ctl().prepare(null);
    expect(st().status, NavStatus.error);
    expect(st().error, NavError.noDestination);
    expect(source.watches, isEmpty);
    await ctl().prepare(const LatLng(0, 0));
    expect(st().error, NavError.noDestination, reason: '0,0 is not a place');
    done();
  });

  for (final (access, error) in [
    (LocationAccess.denied, NavError.permissionDenied),
    (LocationAccess.deniedForever, NavError.permissionBlocked),
    (LocationAccess.serviceOff, NavError.serviceOff),
  ]) {
    testWidgets('location ${access.name}: explained, no route requested', (tester) async {
      source.access = access;
      await ctl().prepare(destination);
      expect(st().status, NavStatus.error);
      expect(st().error, error);
      expect(routing.calls, isEmpty);
      done();
    });
  }

  testWidgets('no GPS fix in time: an error you can retry', (tester) async {
    final f = ctl().prepare(destination);
    await tester.pump();
    await tester.pump(LocationProfile.navigation.firstFixTimeout + const Duration(seconds: 1));
    await f;
    expect(st().error, NavError.noFix);

    final again = ctl().retry();
    await tester.pump();
    source.emit(at(start));
    await tester.pump();
    await again;
    expect(st().status, NavStatus.ready);
    done();
  });

  testWidgets('a full trip: locating → ready → navigating (screen kept on) → arrived (GPS and screen released)', (tester) async {
    await ready(tester);
    expect(st().status, NavStatus.ready);
    expect(routing.calls.single.$1, start, reason: 'routed from the real GPS position');
    expect(routing.calls.single.$2, destination);
    expect(st().route!.distance, closeTo(3672.6, 0.1));

    await ctl().start();
    expect(st().status, NavStatus.navigating);
    expect(awake.on, isTrue);
    expect(st().progress!.stepIndex, 0);
    expect(source.watches.last, LocationProfile.navigation);

    var lastStep = 0;
    for (var along = 0.0; along < line.length - 100; along += 40) {
      source.emit(at(line.pointAt(along)));
      await tester.pump();
      expect(st().progress!.stepIndex, greaterThanOrEqualTo(lastStep));
      lastStep = st().progress!.stepIndex;
    }
    expect(lastStep, greaterThan(4));
    expect(st().status, NavStatus.navigating);

    source.emit(at(destination));
    await tester.pump();
    expect(st().status, NavStatus.arrived);
    expect(st().arrivedAt, isNotNull);
    expect(awake.on, isFalse);
    expect(source.listening, isFalse, reason: 'GPS stops once arrived');
    done();
  });

  testWidgets('routing problems are told apart: offline, no route, far from a road, service trouble', (tester) async {
    for (final (failure, isOnline, expected) in [
      (RoutingFailure.network, false, NavError.offline),
      (RoutingFailure.timeout, false, NavError.offline),
      (RoutingFailure.network, true, NavError.routing),
      (RoutingFailure.noRoute, true, NavError.noRoute),
      (RoutingFailure.tooFarFromRoad, true, NavError.farFromRoad),
      (RoutingFailure.unavailable, true, NavError.routing),
    ]) {
      c.dispose();
      online = isOnline;
      setUpContainer();
      await tester.pump();
      routing.failure = failure;
      await ready(tester);
      expect(st().status, NavStatus.error, reason: '$failure');
      expect(st().error, expected, reason: '$failure online=$isOnline');
    }
    done();
  });

  testWidgets('choosing an alternative guides along that route', (tester) async {
    routing.fixture = 'model_town_to_johar_town';
    await ready(tester);
    expect(st().result!.all, hasLength(2));
    ctl().selectRoute(1);
    expect(st().selected, 1);
    expect(st().route!.distance, closeTo(9101, 1));
    expect(st().otherRoutes.single.distance, closeTo(7548, 1));
    ctl().selectRoute(7);
    expect(st().selected, 1, reason: 'out of range ignored');
    await ctl().start();
    source.emit(at(st().route!.points.first));
    await tester.pump();
    expect(st().progress!.remainingDistance, closeTo(9101, 9101 * 0.02));
    done();
  });

  testWidgets('in the background guidance pauses, and resumes in the foreground', (tester) async {
    await ready(tester);
    await ctl().start();
    c.read(deviceLocationProvider.notifier).appHidden();
    await tester.pump();
    expect(st().status, NavStatus.paused);
    expect(source.listening, isFalse);
    c.read(deviceLocationProvider.notifier).appShown();
    await tester.pump();
    await tester.pump();
    expect(st().status, NavStatus.navigating);
    expect(source.listening, isTrue);
    done();
  });

  testWidgets('a lost GPS signal is shown, guidance continues when it returns', (tester) async {
    await ready(tester);
    await ctl().start();
    source.emit(at(line.pointAt(100)));
    await tester.pump();
    await tester.pump(LocationProfile.navigation.staleAfter + const Duration(seconds: 1));
    expect(st().signalLost, isTrue);
    expect(st().status, NavStatus.navigating);
    source.emit(at(line.pointAt(160)));
    await tester.pump();
    expect(st().signalLost, isFalse);
    done();
  });

  testWidgets('closing the screen mid-trip (no End) still lets the screen sleep', (tester) async {
    await ready(tester);
    await ctl().start();
    expect(awake.on, isTrue);
    done(); // disposes the session, as leaving the screen does
    expect(awake.on, isFalse);
  });

  testWidgets('ending navigation keeps GPS on while live sharing still needs it', (tester) async {
    await ready(tester);
    await ctl().start();
    await c.read(deviceLocationProvider.notifier).request('sharing', LocationProfile.sharing);
    ctl().end();
    await tester.pump();
    expect(source.listening, isTrue, reason: 'sharing continues');
    expect(source.watches.last, LocationProfile.sharing);
    c.read(deviceLocationProvider.notifier).release('sharing');
    await tester.pump();
    expect(source.listening, isFalse);
    done();
  });

  testWidgets('ending stops GPS and lets the screen sleep', (tester) async {
    await ready(tester);
    await ctl().start();
    expect(awake.on, isTrue);
    ctl().end();
    await tester.pump();
    expect(st().status, NavStatus.cancelled);
    expect(awake.on, isFalse);
    expect(source.listening, isFalse);
    source.emit(at(destination));
    await tester.pump();
    expect(st().status, NavStatus.cancelled, reason: 'no late updates after ending');
    done();
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/features/navigation/data/osrm_routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/domain/navigation_engine.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';
import 'package:skill_bridge/features/navigation/presentation/nav_text.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

RouteResult load(String name) => OsrmRoutingService.parseResponse(
      jsonDecode(File('test/fixtures/osrm/$name.json').readAsStringSync()),
      origin: const LatLng(0.1, 0.1),
      destination: const LatLng(0.2, 0.2),
      fetchedAt: DateTime(2026),
    );

/// A point [metres] to the side of [p] (deterministic "GPS noise").
LatLng jitter(LatLng p, int i, double metres) => const Distance().offset(p, metres * math.sin(i * 1.7), (i * 73) % 360);

void main() {
  final now = DateTime(2026, 11, 14, 10);

  group('NavigationEngine on Minar-e-Pakistan → Badshahi Mosque', () {
    final route = load('lahore_route').primary;

    test('at the start: first maneuver ahead, the whole trip left, arrival time from the engine', () {
      final e = NavigationEngine(route);
      final p = e.update(route.points.first, now: now);
      expect(p.stepIndex, 0);
      expect(p.nextStep!.maneuver.type, ManeuverType.turn);
      expect(p.nextStep!.maneuver.modifier, TurnModifier.left);
      expect(p.distanceToManeuver, closeTo(route.steps.first.distance, 10));
      expect(p.remainingDistance, closeTo(route.distance, route.distance * 0.01));
      expect(p.eta.difference(now).inSeconds, closeTo(route.duration, route.duration * 0.02));
      expect(p.arrived, isFalse);
    });

    test('driving the route with GPS noise: steps advance in order, distances fall, arrival is detected', () {
      final e = NavigationEngine(route);
      final line = RouteLine(route.points);
      var lastStep = 0;
      var lastRemaining = double.infinity;
      final seen = <int>{};
      NavProgress? last;
      for (var along = 0.0, i = 0; along <= line.length; along += 15, i++) {
        final p = e.update(jitter(line.pointAt(along), i, 6), now: now, accuracy: 8);
        expect(p.stepIndex, greaterThanOrEqualTo(lastStep), reason: 'never goes back a step at $along m');
        expect(p.remainingDistance, lessThanOrEqualTo(lastRemaining + 1), reason: 'distance left never grows at $along m');
        expect(p.distanceFromRoute, lessThan(10));
        lastStep = p.stepIndex;
        lastRemaining = p.remainingDistance;
        seen.add(p.stepIndex);
        last = p;
        if (p.arrived) break;
      }
      // Every step longer than the 15 m sampling is reached (step 6 is an
      // 8 m jog between two turns; the "then …" hint covers such steps).
      final longSteps = [for (var i = 0; i < route.steps.length - 1; i++) if (route.steps[i].distance > 15) i];
      expect(seen, containsAll(longSteps), reason: 'every maneuver was reached');
      expect(last!.arrived, isTrue);
      expect(last.remainingDistance, 0);
      expect(last.remainingDuration, 0);
      expect(last.currentStep.maneuver.type, ManeuverType.arrive);
    });

    test('distance to the next turn counts down within a step and resets after it', () {
      final e = NavigationEngine(route);
      final line = RouteLine(route.points);
      final turn1 = e.stepStartAt(1);
      final a = e.update(line.pointAt(turn1 - 200), now: now);
      final b = e.update(line.pointAt(turn1 - 50), now: now);
      expect(a.stepIndex, 0);
      expect(a.distanceToManeuver, closeTo(200, 3));
      expect(b.distanceToManeuver, closeTo(50, 3));
      final c = e.update(line.pointAt(turn1 + 30), now: now);
      expect(c.stepIndex, 1, reason: 'passed the turn');
      expect(c.distanceToManeuver, closeTo(e.stepStartAt(2) - turn1 - 30, 3));
    });

    test('jitter just behind the last position doesn\'t undo progress; standing at a junction doesn\'t flip steps', () {
      final e = NavigationEngine(route);
      final line = RouteLine(route.points);
      final turn1 = e.stepStartAt(1);
      final ahead = e.update(line.pointAt(turn1 + 20), now: now);
      final back = e.update(line.pointAt(turn1 + 5), now: now);
      expect(back.stepIndex, ahead.stepIndex);
      expect(back.snap.distanceAlong, ahead.snap.distanceAlong);
    });

    test('far from the route the distance is reported (for off-route detection) without crashing', () {
      final e = NavigationEngine(route);
      final off = const Distance().offset(route.points.first, 150, 0);
      final p = e.update(off, now: now);
      expect(p.distanceFromRoute, greaterThan(60));
      expect(p.arrived, isFalse);
    });

    test('arriving: within 30 m of the end on the route', () {
      final e = NavigationEngine(route);
      final line = RouteLine(route.points);
      for (var along = 0.0; along < line.length - 200; along += 50) {
        e.update(line.pointAt(along), now: now);
      }
      expect(e.update(line.pointAt(line.length - 60), now: now).arrived, isFalse);
      expect(e.update(line.pointAt(line.length - 20), now: now).arrived, isTrue);
      expect(e.update(line.pointAt(line.length - 60), now: now).arrived, isTrue, reason: 'arrival sticks');
    });
  });

  test('passing right behind the destination early in a trip is not arriving', () {
    // A U-shaped trip: out 600 m east, 100 m south, back 600 m west, ending
    // 100 m south of where it passed at the start... and an early leg that
    // runs 20 m from the end point.
    const o = LatLng(31.5, 74.3);
    final d = const Distance();
    final a = d.offset(o, 600, 90);
    final b = d.offset(a, 100, 180);
    final end = d.offset(b, 580, 270);
    final pts = [d.offset(end, 20, 0), o, a, b, end];
    final route = NavRoute(
      points: pts,
      distance: 1300,
      duration: 200,
      legs: [
        RouteLeg(distance: 1300, duration: 200, steps: [
          RouteStep(maneuver: Maneuver(type: ManeuverType.depart, modifier: TurnModifier.none, location: pts.first), distance: 1300, duration: 200, geometry: pts),
          RouteStep(maneuver: Maneuver(type: ManeuverType.arrive, modifier: TurnModifier.none, location: end), distance: 0, duration: 0, geometry: [end]),
        ]),
      ],
    );
    final e = NavigationEngine(route);
    // At the start the user is 20 m from the end point but 1.3 km from it by road.
    final p = e.update(pts.first, now: now, accuracy: 10);
    expect(p.arrived, isFalse);
    final line = RouteLine(pts);
    expect(e.update(line.pointAt(line.length - 10), now: now).arrived, isTrue);
  });

  test('far from the route, its end being the nearest point is not arriving', () {
    // A straight 1 km route east; the user carries on 300 m past its end.
    const o = LatLng(31.5, 74.3);
    final d = const Distance();
    final end = d.offset(o, 1000, 90);
    final pts = [o, d.offset(o, 500, 90), end];
    final route = NavRoute(points: pts, distance: 1000, duration: 120, legs: [
      RouteLeg(distance: 1000, duration: 120, steps: [
        RouteStep(maneuver: Maneuver(type: ManeuverType.depart, modifier: TurnModifier.none, location: o), distance: 1000, duration: 120, geometry: pts),
        RouteStep(maneuver: Maneuver(type: ManeuverType.arrive, modifier: TurnModifier.none, location: end), distance: 0, duration: 0, geometry: [end]),
      ]),
    ]);
    final e = NavigationEngine(route);
    final p = e.update(d.offset(end, 300, 90), now: now);
    expect(p.remainingDistance, lessThan(1), reason: 'the end is the nearest point of the route');
    expect(p.distanceFromRoute, closeTo(300, 2));
    expect(p.arrived, isFalse);
    expect(e.update(d.offset(end, 10, 90), now: now).arrived, isTrue, reason: 'just past the end is arriving');
  });

  test('a route that comes back along the same road after a U-turn is followed, not confused', () {
    final route = load('model_town_to_johar_town').primary;
    final e = NavigationEngine(route);
    final line = RouteLine(route.points);
    for (var along = 0.0; along <= 4000; along += 20) {
      e.update(line.pointAt(along), now: now);
    }
    final p = e.update(line.pointAt(4000), now: now);
    expect(p.snap.distanceAlong, closeTo(4000, 25), reason: 'on the way back, not the way out');
    expect(route.steps[p.stepIndex].maneuver.modifier, TurnModifier.uturn);
  });

  group('instruction text', () {
    late AppLocalizations en;
    late AppLocalizations ur;
    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      ur = await AppLocalizations.delegate.load(const Locale('ur'));
    });

    test('every recorded maneuver reads naturally in English, with road names', () {
      final lahore = load('lahore_route').primary.steps;
      expect(instructionFor(en, lahore[0]), startsWith('Head '));
      expect(instructionFor(en, lahore[1]), 'Turn left');
      expect(instructionFor(en, lahore[2]), 'Turn sharp left onto Iqbal Park Parking Lot');
      expect(instructionFor(en, lahore[3]), 'Continue straight onto سرکلر روڈ');
      expect(instructionFor(en, lahore[4]), 'Bear left onto Ravi Road');
      expect(instructionFor(en, lahore[8]), 'Your destination is on the right');

      final johar = load('model_town_to_johar_town').all.expand((r) => r.steps).toList();
      String textOf(ManeuverType t, TurnModifier m) =>
          instructionFor(en, johar.firstWhere((s) => s.maneuver.type == t && s.maneuver.modifier == m));
      expect(textOf(ManeuverType.continueOn, TurnModifier.uturn), 'Make a U-turn onto Maulana Shaukat Ali Road');
      expect(textOf(ManeuverType.onRamp, TurnModifier.slightLeft), 'Take the ramp on the left');
      expect(textOf(ManeuverType.merge, TurnModifier.slightRight), 'Merge right onto Chaakar Azam Rind Underpass');
      expect(textOf(ManeuverType.offRamp, TurnModifier.slightLeft), 'Take the exit on the left');
      expect(textOf(ManeuverType.endOfRoad, TurnModifier.left), 'At the end of the road, turn left onto Maulana Shaukat Ali Road');
      expect(textOf(ManeuverType.roundabout, TurnModifier.left), startsWith('At the roundabout, take exit '));

      final rotary = load('gulberg_to_dha').primary.steps.firstWhere((s) => s.maneuver.type == ManeuverType.rotary);
      expect(instructionFor(en, rotary), 'At Hussain Chowk, take exit 3 onto MM Alam Road');
    });

    test('every step has Urdu text that is not the English one', () {
      for (final name in ['lahore_route', 'model_town_to_johar_town', 'gulberg_to_dha']) {
        for (final s in load(name).all.expand((r) => r.steps)) {
          final u = instructionFor(ur, s);
          expect(u.trim(), isNotEmpty);
          expect(u, isNot(instructionFor(en, s)));
        }
      }
      final rotary = load('gulberg_to_dha').primary.steps.firstWhere((s) => s.maneuver.type == ManeuverType.rotary);
      expect(instructionFor(ur, rotary), contains('Hussain Chowk'));
      expect(instructionFor(ur, rotary), contains('3'));
    });

    test('compass words, distances and times', () {
      expect(compassWord(en, 2), 'north');
      expect(compassWord(en, 46), 'northeast');
      expect(compassWord(en, 268), 'west');
      expect(compassWord(en, 359), 'north');
      expect(formatNavDistance(en, 4), '0 m');
      expect(formatNavDistance(en, 137), '140 m');
      expect(formatNavDistance(en, 424), '400 m');
      expect(formatNavDistance(en, 990), '1 km');
      expect(formatNavDistance(en, 3672.6), '3.7 km');
      expect(formatNavDistance(en, 12400), '12 km');
      expect(formatNavDistance(ur, 3672.6), '3.7 کلومیٹر');
      expect(formatNavDuration(en, 20), 'Under 1 min');
      expect(formatNavDuration(en, 666), '12 min');
      expect(formatNavDuration(en, 3 * 3600 + 120), '3 h 2 min');
      expect(formatNavDuration(ur, 666), '12 منٹ');
    });

    test('arrows match the maneuver; U-turns and roundabouts follow keep-left traffic', () {
      final johar = load('model_town_to_johar_town').all.expand((r) => r.steps).toList();
      IconData iconOf(ManeuverType t, TurnModifier m) => maneuverIcon(johar.firstWhere((s) => s.maneuver.type == t && s.maneuver.modifier == m));
      expect(iconOf(ManeuverType.continueOn, TurnModifier.uturn), Icons.u_turn_right);
      expect(iconOf(ManeuverType.roundabout, TurnModifier.left), Icons.roundabout_left);
      expect(iconOf(ManeuverType.onRamp, TurnModifier.slightLeft), Icons.ramp_left);
      expect(iconOf(ManeuverType.merge, TurnModifier.slightRight), Icons.merge);
      expect(iconOf(ManeuverType.turn, TurnModifier.right), Icons.turn_right);
      final lahore = load('lahore_route').primary.steps;
      expect(maneuverIcon(lahore.last), Icons.sports_score);
      expect(maneuverIcon(lahore[2]), Icons.turn_sharp_left);
    });
  });
}

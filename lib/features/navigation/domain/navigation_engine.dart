import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';

/// Turn-by-turn progress along one route (Navigation phase 6). Pure Dart.
///
/// Each position is placed on the route; from that come the step being
/// driven, the next maneuver and the distance to it, what is left (road
/// distance and the engine's own step times), the arrival time, how far the
/// user is from the route, and arrival. Off-route detection and rerouting
/// (phase 7) build on [NavProgress.distanceFromRoute].

class NavProgress {
  const NavProgress({
    required this.snap,
    required this.stepIndex,
    required this.distanceToManeuver,
    required this.remainingDistance,
    required this.remainingDuration,
    required this.eta,
    required this.arrived,
    required this.steps,
  });

  /// Where the user is on the route.
  final RouteSnap snap;

  /// The step being driven (its maneuver is behind the user).
  final int stepIndex;

  /// Road metres to the next maneuver (or to the destination).
  final double distanceToManeuver;

  /// Road metres and seconds left.
  final double remainingDistance;
  final double remainingDuration;
  final DateTime eta;
  final bool arrived;
  final List<RouteStep> steps;

  /// Metres between the user and the route.
  double get distanceFromRoute => snap.distanceToRoute;

  RouteStep get currentStep => steps[stepIndex];

  /// The maneuver coming up (the arrive step at the end).
  RouteStep? get nextStep => stepIndex + 1 < steps.length ? steps[stepIndex + 1] : null;

  /// The maneuver after that, for "then …" hints.
  RouteStep? get stepAfterNext => stepIndex + 2 < steps.length ? steps[stepIndex + 2] : null;

  int get nextStepIndex => math.min(stepIndex + 1, steps.length - 1);
}

class NavigationEngine {
  NavigationEngine(this.route, {this.arrivalRadius = 30})
      : line = RouteLine(route.points),
        steps = route.steps {
    // Where each step's maneuver falls along the line. Step lengths come
    // from the engine and add up to the route length to within metres;
    // they are scaled onto the drawn line so both agree exactly.
    final total = steps.fold<double>(0, (a, s) => a + s.distance);
    final scale = total > 0 ? line.length / total : 1.0;
    _toStepMetres = scale > 0 ? 1 / scale : 1.0;
    var at = 0.0;
    for (final s in steps) {
      _stepStart.add(at);
      at += s.distance * scale;
    }
  }

  final NavRoute route;
  final RouteLine line;
  final List<RouteStep> steps;

  /// Within this many metres of the destination (by road or in a straight
  /// line) counts as arrived.
  final double arrivalRadius;

  final List<double> _stepStart = [];
  late final double _toStepMetres;
  int _segment = 0;
  bool _arrived = false;
  double _bestAlong = 0;

  /// A maneuver counts as passed this many metres after its point, so GPS
  /// jitter at a junction doesn't flip the instruction back and forth.
  static const passMargin = 8.0;

  /// Furthest from the route (plus GPS error) that arrival can count.
  static const arrivalOnRoute = 40.0;

  /// Road metres left within which arriving "as the crow flies" counts.
  static const maxStraightArrivalRemaining = 150.0;

  /// Metres along the route where step [i] begins.
  double stepStartAt(int i) => _stepStart[i];

  /// Places [position] on the route and works out progress.
  NavProgress update(LatLng position, {required DateTime now, double accuracy = 0}) {
    if (steps.isEmpty) throw StateError('route has no steps');
    // Search forward from where the user was (a little behind, for jitter),
    // so a route that comes back along the same road after a U-turn isn't
    // confused with its earlier part. If that window is far off, look at the
    // whole route.
    var snap = line.snap(position, fromSegment: math.max(0, _segment - 3), lookAhead: 80);
    if (snap.distanceToRoute > 40) {
      final whole = line.snap(position);
      if (whole.distanceToRoute + 20 < snap.distanceToRoute) snap = whole;
    }
    _segment = snap.segment;

    // Progress only moves back for a real reversal (more than GPS noise).
    var along = snap.distanceAlong;
    if (along < _bestAlong && _bestAlong - along < 25) along = _bestAlong;
    _bestAlong = math.max(_bestAlong, along);

    var step = 0;
    for (var i = 1; i < steps.length; i++) {
      if (_stepStart[i] + passMargin <= along) step = i;
    }
    final nextStart = step + 1 < steps.length ? _stepStart[step + 1] : line.length;
    final remaining = math.max(0.0, line.length - along);
    final straightToEnd = const Distance().as(LengthUnit.Meter, position, line.points.last);
    // A straight-line arrival is trusted only near the end of the route (a
    // road can pass right behind the destination before looping round to
    // it), allowing for GPS error.
    // Both ways require being on the route: far from it, the nearest point
    // of the route can be its end without the user being anywhere near.
    final onRoute = snap.distanceToRoute <= arrivalOnRoute + math.min(accuracy, 20);
    if (onRoute &&
        (remaining <= arrivalRadius || (straightToEnd <= arrivalRadius + math.min(accuracy, 20) && remaining <= maxStraightArrivalRemaining))) {
      _arrived = true;
    }
    final duration = _arrived ? 0.0 : remainingDurationAt(route, along * _toStepMetres);
    return NavProgress(
      snap: RouteSnap(point: snap.point, distanceToRoute: snap.distanceToRoute, distanceAlong: along, segment: snap.segment),
      stepIndex: _arrived ? steps.length - 1 : step,
      distanceToManeuver: _arrived ? 0 : math.max(0.0, nextStart - along),
      remainingDistance: _arrived ? 0 : remaining,
      remainingDuration: duration,
      eta: estimateArrival(now, duration),
      arrived: _arrived,
      steps: steps,
    );
  }

  bool get arrived => _arrived;
}

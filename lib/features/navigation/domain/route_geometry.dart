import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';

/// Measuring along a route line (Navigation phase 5): how far the user is
/// from the route, how far along it they are, and what is left. Pure Dart.
///
/// Distances along the line use the haversine distance between the
/// route's own points, so they add up to the road length the engine
/// reported (to within a few metres), never a straight line to the
/// destination.

const _distance = Distance();
const _earthRadius = 6371008.8;

/// Where a position falls on a route line.
class RouteSnap {
  const RouteSnap({required this.point, required this.distanceToRoute, required this.distanceAlong, required this.segment});

  /// Nearest point on the line.
  final LatLng point;

  /// Metres from the position to [point].
  final double distanceToRoute;

  /// Metres from the start of the line to [point].
  final double distanceAlong;

  /// Index of the segment (points[segment] → points[segment + 1]).
  final int segment;
}

/// A route line with cumulative distances, for fast repeated snapping.
class RouteLine {
  RouteLine(List<LatLng> points)
      : points = List.unmodifiable(points),
        _cumulative = _cumulate(points);

  final List<LatLng> points;
  final List<double> _cumulative;

  static List<double> _cumulate(List<LatLng> pts) {
    final out = List<double>.filled(pts.length, 0);
    for (var i = 1; i < pts.length; i++) {
      out[i] = out[i - 1] + _distance.as(LengthUnit.Meter, pts[i - 1], pts[i]);
    }
    return out;
  }

  /// Total length in metres.
  double get length => _cumulative.isEmpty ? 0 : _cumulative.last;

  /// Metres from the start to point [index].
  double distanceAt(int index) => _cumulative[index];

  /// The nearest point of the line to [p]. Searches segments from
  /// [fromSegment] (so a user moving forward isn't snapped back onto an
  /// earlier, overlapping part of the route) up to [lookAhead] segments.
  RouteSnap snap(LatLng p, {int fromSegment = 0, int? lookAhead}) {
    if (points.isEmpty) throw StateError('empty route');
    if (points.length == 1) {
      return RouteSnap(point: points.first, distanceToRoute: _distance.as(LengthUnit.Meter, p, points.first), distanceAlong: 0, segment: 0);
    }
    final start = fromSegment.clamp(0, points.length - 2);
    final end = lookAhead == null ? points.length - 2 : math.min(points.length - 2, start + lookAhead);

    // Local flat projection around p (metres): accurate at city scale.
    final cosLat = math.cos(p.latitudeInRad);
    double x(LatLng q) => (q.longitudeInRad - p.longitudeInRad) * cosLat * _earthRadius;
    double y(LatLng q) => (q.latitudeInRad - p.latitudeInRad) * _earthRadius;

    var best = double.infinity;
    var bestSeg = start;
    var bestT = 0.0;
    for (var i = start; i <= end; i++) {
      final ax = x(points[i]), ay = y(points[i]);
      final bx = x(points[i + 1]), by = y(points[i + 1]);
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      // p is the origin (0, 0) in this projection.
      final t = len2 == 0 ? 0.0 : ((-ax) * dx + (-ay) * dy) / len2;
      final tc = t.clamp(0.0, 1.0);
      final px = ax + tc * dx, py = ay + tc * dy;
      final d2 = px * px + py * py;
      if (d2 < best) {
        best = d2;
        bestSeg = i;
        bestT = tc;
      }
    }
    final a = points[bestSeg], b = points[bestSeg + 1];
    final on = LatLng(a.latitude + (b.latitude - a.latitude) * bestT, a.longitude + (b.longitude - a.longitude) * bestT);
    final segLen = _cumulative[bestSeg + 1] - _cumulative[bestSeg];
    return RouteSnap(
      point: on,
      distanceToRoute: math.sqrt(best),
      distanceAlong: _cumulative[bestSeg] + segLen * bestT,
      segment: bestSeg,
    );
  }

  /// Metres left from [snap] to the end of the line.
  double remainingFrom(RouteSnap snap) => math.max(0, length - snap.distanceAlong);

  /// The point [along] metres from the start (clamped to the line).
  LatLng pointAt(double along) {
    if (points.length < 2 || along <= 0) return points.first;
    if (along >= length) return points.last;
    var i = 1;
    while (i < _cumulative.length && _cumulative[i] < along) {
      i++;
    }
    final segLen = _cumulative[i] - _cumulative[i - 1];
    final t = segLen == 0 ? 0.0 : (along - _cumulative[i - 1]) / segLen;
    final a = points[i - 1], b = points[i];
    return LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t);
  }
}

/// Seconds left on [route] from [distanceAlong] metres, using each step's
/// own time (slow streets stay slow), with the current step pro rata.
double remainingDurationAt(NavRoute route, double distanceAlong) {
  final steps = route.steps;
  if (steps.isEmpty || route.distance <= 0) return 0;
  var start = 0.0;
  var remaining = 0.0;
  for (final s in steps) {
    final end = start + s.distance;
    if (distanceAlong <= start) {
      remaining += s.duration;
    } else if (distanceAlong < end && s.distance > 0) {
      remaining += s.duration * (end - distanceAlong) / s.distance;
    }
    start = end;
  }
  return remaining;
}

/// Arrival time after [remainingSeconds] from [now].
DateTime estimateArrival(DateTime now, double remainingSeconds) =>
    now.add(Duration(milliseconds: (math.max(0, remainingSeconds) * 1000).round()));

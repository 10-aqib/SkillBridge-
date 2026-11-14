import 'dart:math' as math;

/// Decides when the user has really left the route (Navigation phase 7).
/// Pure Dart.
///
/// GPS wanders, so a single far-off fix is never enough:
/// - the allowed distance grows with the fix's reported error;
/// - fixes too inaccurate to judge (or while the signal is lost) are ignored,
///   neither confirming nor clearing anything;
/// - the user must stay beyond the limit for [sustainFixes] fixes AND
///   [sustainTime] before it counts;
/// - coming back well inside the limit clears it.
/// Going back along the route the wrong way (progress dropping a long way)
/// counts as off route too.

enum RouteAdherence {
  /// On the route.
  onRoute,

  /// Beyond the limit, but not for long enough yet.
  drifting,

  /// Off the route: time to find a new one.
  offRoute,
}

class OffRouteDetector {
  OffRouteDetector({
    this.baseLimit = 35,
    this.maxLimit = 80,
    this.ignoreAccuracyAbove = 50,
    this.sustainFixes = 3,
    this.sustainTime = const Duration(seconds: 5),
    this.wrongWayMetres = 60,
  });

  /// Metres from the route allowed with a precise fix.
  final double baseLimit;

  /// Largest limit, however rough the fix.
  final double maxLimit;

  /// Fixes less accurate than this are not used to judge.
  final double ignoreAccuracyAbove;
  final int sustainFixes;
  final Duration sustainTime;

  /// Progress dropping more than this below the best so far is going the
  /// wrong way.
  final double wrongWayMetres;

  int _count = 0;
  DateTime? _since;
  RouteAdherence _state = RouteAdherence.onRoute;

  RouteAdherence get state => _state;

  /// The allowed distance for a fix with [accuracy] metres of error.
  double limitFor(double accuracy) => math.min(maxLimit, math.max(baseLimit, accuracy * 1.5 + 10));

  /// One position: [distanceFromRoute] metres off the route, [accuracy]
  /// metres of GPS error, [progressDrop] metres behind the furthest point
  /// reached along the route.
  RouteAdherence update({
    required double distanceFromRoute,
    required double accuracy,
    required DateTime at,
    double progressDrop = 0,
    bool signalLost = false,
  }) {
    if (signalLost || !accuracy.isFinite || accuracy > ignoreAccuracyAbove || !distanceFromRoute.isFinite) return _state;
    final limit = limitFor(accuracy);
    final away = distanceFromRoute > limit || progressDrop > wrongWayMetres;
    if (away) {
      _count++;
      _since ??= at;
      final long = at.difference(_since!) >= sustainTime;
      _state = _count >= sustainFixes && long ? RouteAdherence.offRoute : RouteAdherence.drifting;
    } else if (distanceFromRoute <= limit * 0.7 && progressDrop <= wrongWayMetres / 2) {
      reset();
    }
    // Between 70 % and 100 % of the limit: keep the current state (no
    // flapping on the edge).
    return _state;
  }

  /// Start fresh (a new route, or back on it).
  void reset() {
    _count = 0;
    _since = null;
    _state = RouteAdherence.onRoute;
  }
}

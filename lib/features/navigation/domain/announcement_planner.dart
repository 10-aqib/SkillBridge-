import 'dart:math' as math;

import 'package:skill_bridge/features/navigation/domain/navigation_engine.dart';

/// Decides what voice guidance says and when (Navigation phase 7). Pure
/// Dart; the words come from the presentation layer.
///
/// - Each maneuver is announced at most once per distance band: early (for
///   long stretches), near, and at the turn. If the user first appears
///   already inside a band, only that band is said; nothing is stacked.
/// - "Approaching your destination" and "You have arrived" are said once.
/// - A new route starts fresh, and is announced once.
/// - Nothing about the route is said while the user is well off it.
/// - Nothing is said unless asked while navigating; muting still marks
///   announcements as handled, so unmuting never plays a backlog.

enum AnnouncementKind { start, early, near, now, approaching, arrived, rerouted }

class Announcement {
  const Announcement(this.kind, {this.stepIndex, this.distance = 0});
  final AnnouncementKind kind;

  /// The maneuver's step, for maneuver announcements.
  final int? stepIndex;

  /// Road metres to the maneuver when said.
  final double distance;

  @override
  String toString() => 'Announcement(${kind.name}, step $stepIndex, ${distance.round()} m)';
}

class AnnouncementPlanner {
  AnnouncementPlanner({this.earlyAt = 500, this.nowAt = 30, this.approachingAt = 150, this.thenWithin = 150, this.quietOffRouteAbove = 50});

  /// Early warning distance, used only when the stretch before the maneuver
  /// is long enough to need it.
  final double earlyAt;

  /// Metres off the route beyond which nothing about it is said.
  final double quietOffRouteAbove;

  /// "Turn now" distance.
  final double nowAt;

  /// "Approaching your destination" when this much road is left.
  final double approachingAt;

  /// A maneuver closer than this after the previous one is said together
  /// with it ("…, then turn right"), so its own early/near warnings are
  /// skipped; only its "now" remains.
  final double thenWithin;

  final _said = <String>{};
  int _routeVersion = -1;

  /// Near-band distance for [speed] m/s: about 10 seconds ahead, never
  /// closer than 80 m nor further than 250 m.
  double nearAt(double? speed) => speed == null || !speed.isFinite || speed <= 0 ? 150 : (speed * 10).clamp(80, 250).toDouble();

  /// The next thing to say for [progress] on route [routeVersion] (bump it
  /// when the route changes), or null to stay quiet.
  Announcement? next(NavProgress progress, {required int routeVersion, double? speed}) {
    if (routeVersion != _routeVersion) {
      final rerouted = _routeVersion >= 0;
      _routeVersion = routeVersion;
      _said.clear();
      if (rerouted) {
        _said.add('rerouted');
        return const Announcement(AnnouncementKind.rerouted);
      }
      _said.add('start');
      final next = progress.nextStepIndex;
      _markPassedBands(next, progress.distanceToManeuver, speed);
      _coverFollowing(progress, next);
      return Announcement(AnnouncementKind.start, stepIndex: next, distance: progress.distanceToManeuver);
    }

    if (progress.arrived) return _once('arrived', const Announcement(AnnouncementKind.arrived));
    // Off the route: its turns (and "approaching", when its end happens to
    // be the nearest point) would mislead. Stay quiet; nothing is marked as
    // said, so guidance resumes once back on this route or a new one.
    if (progress.distanceFromRoute > quietOffRouteAbove) return null;
    final next = progress.nextStepIndex;
    final isLast = next == progress.steps.length - 1;
    if (isLast && progress.remainingDistance <= approachingAt) {
      return _once('approaching', const Announcement(AnnouncementKind.approaching));
    }
    if (isLast) return null; // the arrive step is covered by the two above

    final d = progress.distanceToManeuver;
    final near = nearAt(speed);
    // The tightest band the user is in, said only if not said yet; lower
    // bands imply the wider ones are past.
    final AnnouncementKind? band = d <= nowAt
        ? AnnouncementKind.now
        : d <= near
            ? AnnouncementKind.near
            : d <= earlyAt && progress.currentStep.distance > earlyAt + 200
                ? AnnouncementKind.early
                : null;
    if (band == null) return null;
    final key = '$next:${band.name}';
    if (_said.contains(key)) return null;
    _markPassedBands(next, d, speed);
    _said.add(key);
    if (band != AnnouncementKind.early) _coverFollowing(progress, next);
    return Announcement(band, stepIndex: next, distance: d);
  }

  /// When the maneuver after [step] comes within [thenWithin], it was said
  /// as "…, then …": skip its early and near warnings.
  void _coverFollowing(NavProgress progress, int step) {
    if (step + 1 < progress.steps.length && progress.steps[step].distance < thenWithin) {
      _said
        ..add('${step + 1}:${AnnouncementKind.early.name}')
        ..add('${step + 1}:${AnnouncementKind.near.name}');
    }
  }

  /// Marks every band at or wider than [distance] as said for [step].
  void _markPassedBands(int step, double distance, double? speed) {
    if (distance <= math.max(earlyAt, nearAt(speed))) _said.add('$step:${AnnouncementKind.early.name}');
    if (distance <= nearAt(speed)) _said.add('$step:${AnnouncementKind.near.name}');
    if (distance <= nowAt) _said.add('$step:${AnnouncementKind.now.name}');
  }

  Announcement? _once(String key, Announcement a) {
    if (_said.contains(key)) return null;
    _said.add(key);
    return a;
  }
}

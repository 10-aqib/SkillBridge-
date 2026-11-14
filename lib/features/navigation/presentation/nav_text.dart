import 'package:flutter/material.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

/// Words and icons for turn-by-turn directions (Navigation phase 6). Built
/// from the routing engine's maneuver data in English and Urdu, not from the
/// engine's own English text. Voice guidance (phase 7) reads the same text.

/// SkillBridge serves Pakistan, where traffic keeps left. The public OSRM
/// server labels Lahore steps "right", so a step's own value is trusted
/// only when it says left.
const appKeepsLeft = true;

bool _keepsLeft(RouteStep step) => step.keepsLeft || appKeepsLeft;

/// The spoken/written instruction for the maneuver that starts [step].
String instructionFor(AppLocalizations l, RouteStep step) {
  final m = step.maneuver;
  final road = step.roadLabel;
  String onto(String action) => road.isEmpty ? action : l.navOnto(action, road);
  String side(String left, String right, String neither) =>
      m.modifier.isLeft ? left : (m.modifier.isRight ? right : neither);

  String turn() => switch (m.modifier) {
        TurnModifier.left => l.navTurnLeft,
        TurnModifier.right => l.navTurnRight,
        TurnModifier.slightLeft => l.navBearLeft,
        TurnModifier.slightRight => l.navBearRight,
        TurnModifier.sharpLeft => l.navSharpLeft,
        TurnModifier.sharpRight => l.navSharpRight,
        TurnModifier.uturn => l.navUTurn,
        TurnModifier.straight => l.navGoStraight,
        TurnModifier.none => l.navContinue,
      };

  switch (m.type) {
    case ManeuverType.depart:
      final bearing = m.bearingAfter;
      return onto(bearing == null ? l.navStartOff : l.navHead(compassWord(l, bearing)));
    case ManeuverType.arrive:
      return side(l.navArriveLeft, l.navArriveRight, l.navArrive);
    case ManeuverType.turn:
    case ManeuverType.notification:
    case ManeuverType.unknown:
      return onto(turn());
    case ManeuverType.newName:
      return onto(m.modifier == TurnModifier.straight || m.modifier == TurnModifier.none ? l.navContinue : turn());
    case ManeuverType.continueOn:
      return onto(m.modifier == TurnModifier.uturn ? l.navUTurn : (m.modifier.isLeft || m.modifier.isRight ? side(l.navKeepLeft, l.navKeepRight, l.navContinue) : l.navGoStraight));
    case ManeuverType.merge:
      return onto(side(l.navMergeLeft, l.navMergeRight, l.navMerge));
    case ManeuverType.onRamp:
      return onto(side(l.navRampLeft, l.navRampRight, l.navRamp));
    case ManeuverType.offRamp:
      return onto(side(l.navExitLeft, l.navExitRight, l.navExitNext));
    case ManeuverType.fork:
      return onto(side(l.navKeepLeft, l.navKeepRight, l.navContinue));
    case ManeuverType.endOfRoad:
      return onto(side(l.navEndOfRoadLeft, l.navEndOfRoadRight, l.navContinue));
    case ManeuverType.roundabout:
    case ManeuverType.rotary:
      final exit = m.exit;
      final name = step.rotaryName;
      if (exit != null && exit > 0) {
        return onto(name != null ? l.navNamedRoundaboutExit(name, exit) : l.navRoundaboutExit(exit));
      }
      return onto(name != null ? l.navEnterNamedRoundabout(name) : l.navEnterRoundabout);
    case ManeuverType.roundaboutTurn:
      return onto(turn());
    case ManeuverType.exitRoundabout:
    case ManeuverType.exitRotary:
      return onto(l.navLeaveRoundabout);
  }
}

/// Eight-point compass word for a bearing in degrees.
String compassWord(AppLocalizations l, double bearing) {
  final words = [l.navNorth, l.navNorthEast, l.navEast, l.navSouthEast, l.navSouth, l.navSouthWest, l.navWest, l.navNorthWest];
  final i = (((bearing % 360) + 22.5) ~/ 45) % 8;
  return words[i];
}

/// Icon for the maneuver that starts [step].
IconData maneuverIcon(RouteStep step) {
  final m = step.maneuver;
  final mod = m.modifier;
  final leftTraffic = _keepsLeft(step);
  IconData turn() => switch (mod) {
        TurnModifier.left => Icons.turn_left,
        TurnModifier.right => Icons.turn_right,
        TurnModifier.slightLeft => Icons.turn_slight_left,
        TurnModifier.slightRight => Icons.turn_slight_right,
        TurnModifier.sharpLeft => Icons.turn_sharp_left,
        TurnModifier.sharpRight => Icons.turn_sharp_right,
        // Where traffic keeps left, U-turns go round to the right.
        TurnModifier.uturn => leftTraffic ? Icons.u_turn_right : Icons.u_turn_left,
        TurnModifier.straight || TurnModifier.none => Icons.straight,
      };
  return switch (m.type) {
    ManeuverType.depart => Icons.navigation_rounded,
    ManeuverType.arrive => Icons.sports_score,
    ManeuverType.merge => Icons.merge,
    ManeuverType.onRamp || ManeuverType.offRamp => mod.isLeft ? Icons.ramp_left : (mod.isRight ? Icons.ramp_right : Icons.straight),
    ManeuverType.fork => mod.isLeft ? Icons.fork_left : (mod.isRight ? Icons.fork_right : Icons.straight),
    ManeuverType.roundabout || ManeuverType.rotary || ManeuverType.roundaboutTurn || ManeuverType.exitRoundabout || ManeuverType.exitRotary =>
      leftTraffic ? Icons.roundabout_left : Icons.roundabout_right,
    ManeuverType.continueOn when mod == TurnModifier.uturn => turn(),
    ManeuverType.continueOn || ManeuverType.newName => mod.isLeft || mod.isRight ? turn() : Icons.straight,
    _ => turn(),
  };
}

/// Road distance for directions: 10 m steps up to 300 m, 50 m steps up to a
/// kilometre, then kilometres (one decimal under 10 km).
String formatNavDistance(AppLocalizations l, double meters) {
  if (meters < 1000) {
    final step = meters < 300 ? 10 : 50;
    final rounded = ((meters / step).round() * step).clamp(0, 1000).toInt();
    if (rounded >= 1000) return l.navKilometres('1');
    return l.navMeters(rounded);
  }
  final km = meters / 1000;
  return l.navKilometres(km < 10 ? km.toStringAsFixed(1) : km.round().toString());
}

/// Time left, rounded up to the minute.
String formatNavDuration(AppLocalizations l, double seconds) {
  if (seconds < 45) return l.navUnderAMinute;
  final minutes = (seconds / 60).ceil();
  if (minutes < 60) return l.navMinutes(minutes);
  return l.navHoursMinutes(minutes ~/ 60, minutes % 60);
}

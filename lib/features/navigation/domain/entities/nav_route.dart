import 'package:latlong2/latlong.dart';

/// A road route from a routing engine (Navigation phase 5). Distances are
/// metres and durations seconds, as the engine gives them; durations assume
/// normal traffic for a car and are estimates, not promises.

/// What the driver does at a step (OSRM maneuver types).
enum ManeuverType {
  depart('depart'),
  arrive('arrive'),
  turn('turn'),
  newName('new name'),
  continueOn('continue'),
  merge('merge'),
  onRamp('on ramp'),
  offRamp('off ramp'),
  fork('fork'),
  endOfRoad('end of road'),
  roundabout('roundabout'),
  rotary('rotary'),
  roundaboutTurn('roundabout turn'),
  exitRoundabout('exit roundabout'),
  exitRotary('exit rotary'),
  notification('notification'),
  unknown('');

  const ManeuverType(this.osrm);
  final String osrm;

  static ManeuverType parse(String? value) =>
      ManeuverType.values.firstWhere((t) => t.osrm == value && t != ManeuverType.unknown, orElse: () => ManeuverType.unknown);

  bool get isRoundabout => this == roundabout || this == rotary || this == roundaboutTurn;
  bool get isRoundaboutExit => this == exitRoundabout || this == exitRotary;
}

/// Direction of a maneuver.
enum TurnModifier {
  uturn('uturn'),
  sharpRight('sharp right'),
  right('right'),
  slightRight('slight right'),
  straight('straight'),
  slightLeft('slight left'),
  left('left'),
  sharpLeft('sharp left'),
  none('');

  const TurnModifier(this.osrm);
  final String osrm;

  static TurnModifier parse(String? value) =>
      TurnModifier.values.firstWhere((m) => m.osrm == value && m != TurnModifier.none, orElse: () => TurnModifier.none);

  bool get isLeft => this == left || this == slightLeft || this == sharpLeft;
  bool get isRight => this == right || this == slightRight || this == sharpRight;
}

class Maneuver {
  const Maneuver({
    required this.type,
    required this.modifier,
    required this.location,
    this.exit,
    this.bearingBefore,
    this.bearingAfter,
  });

  final ManeuverType type;
  final TurnModifier modifier;

  /// Where the maneuver happens.
  final LatLng location;

  /// Roundabout exit number (1 = first exit), when given.
  final int? exit;
  final double? bearingBefore;
  final double? bearingAfter;
}

class RouteStep {
  const RouteStep({
    required this.maneuver,
    required this.distance,
    required this.duration,
    required this.geometry,
    this.name = '',
    this.ref,
    this.destinations,
    this.rotaryName,
    this.mode = 'driving',
    this.drivingSide = 'right',
  });

  /// The maneuver that starts this step.
  final Maneuver maneuver;

  /// Length and time of the step, from its maneuver to the next one.
  final double distance;
  final double duration;
  final List<LatLng> geometry;

  /// Road the step follows after the maneuver ('' when unnamed).
  final String name;

  /// Road number (e.g. "N-5").
  final String? ref;
  final String? destinations;

  /// Name of the roundabout or rotary (e.g. "Hussain Chowk").
  final String? rotaryName;
  final String mode;

  /// 'left' where traffic keeps left (Pakistan), else 'right'.
  final String drivingSide;
  bool get keepsLeft => drivingSide == 'left';

  /// Best label for the road: its name, else its number, else ''.
  String get roadLabel => name.trim().isNotEmpty ? name.trim() : (ref ?? '').trim();
}

class RouteLeg {
  const RouteLeg({required this.steps, required this.distance, required this.duration, this.summary = ''});
  final List<RouteStep> steps;
  final double distance;
  final double duration;

  /// Main roads of the leg, e.g. "Maulana Shaukat Ali Road, Abdul Haq Road".
  final String summary;
}

class NavRoute {
  const NavRoute({required this.points, required this.distance, required this.duration, required this.legs});

  /// Full route line, start to end.
  final List<LatLng> points;
  final double distance;
  final double duration;
  final List<RouteLeg> legs;

  /// All steps of all legs, in order.
  List<RouteStep> get steps => [for (final leg in legs) ...leg.steps];

  String get summary => legs.map((l) => l.summary).where((s) => s.isNotEmpty).join(', ');
}

/// The engine's answer: the recommended route and any alternatives.
class RouteResult {
  const RouteResult({
    required this.primary,
    this.alternatives = const [],
    required this.origin,
    required this.destination,
    required this.fetchedAt,
    this.originSnapDistance,
    this.destinationSnapDistance,
  });

  final NavRoute primary;
  final List<NavRoute> alternatives;

  /// The points that were asked for (the route may start or end a little
  /// away from them, on the nearest road).
  final LatLng origin;
  final LatLng destination;
  final DateTime fetchedAt;

  /// Metres the engine moved each point to reach the nearest road (null
  /// when it didn't say).
  final double? originSnapDistance;
  final double? destinationSnapDistance;

  List<NavRoute> get all => [primary, ...alternatives];
}

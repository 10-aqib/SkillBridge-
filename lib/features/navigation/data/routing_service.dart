import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';

/// Road routing behind an interface (Navigation phase 5), so the engine
/// (public OSRM, a self-hosted OSRM, or another provider) can change without
/// touching the screens. Pure Dart.

enum RoutingFailure {
  /// Coordinates outside the world, or a request the engine refused.
  invalidInput,

  /// The engine found no road route between the points.
  noRoute,

  /// A point is too far from any road the engine knows.
  tooFarFromRoad,

  /// No connection, or the server couldn't be reached.
  network,

  /// The server didn't answer in time.
  timeout,

  /// The server is down, overloaded or rate limiting.
  unavailable,

  /// The answer couldn't be understood.
  malformed,
}

class RoutingException implements Exception {
  const RoutingException(this.failure, [this.detail = '']);
  final RoutingFailure failure;
  final String detail;

  /// Worth trying again later (connection or server trouble), as opposed
  /// to a route that doesn't exist.
  bool get isTransient =>
      failure == RoutingFailure.network || failure == RoutingFailure.timeout || failure == RoutingFailure.unavailable;

  @override
  String toString() => 'RoutingException(${failure.name}${detail.isEmpty ? '' : ': $detail'})';
}

abstract class RoutingService {
  const RoutingService();

  /// The best road route from [origin] to [destination], plus alternatives
  /// when [alternatives] is true and the engine has any. Throws
  /// [RoutingException].
  Future<RouteResult> getRoute(LatLng origin, LatLng destination, {bool alternatives = true});

  /// Only the alternatives (may be empty).
  Future<List<NavRoute>> getAlternativeRoutes(LatLng origin, LatLng destination) async =>
      (await getRoute(origin, destination, alternatives: true)).alternatives;

  /// The steps (maneuvers) of [route], in order.
  List<RouteStep> parseRouteSteps(NavRoute route) => route.steps;

  /// Road distance left on [route] from [position] (metres along the route
  /// from the nearest point on it). Not a straight line.
  double calculateDistance(NavRoute route, LatLng position) {
    final line = RouteLine(route.points);
    return line.remainingFrom(line.snap(position));
  }

  /// Arrival time from [position] on [route], using the engine's own step
  /// times.
  DateTime estimateArrival(NavRoute route, LatLng position, {DateTime? now}) {
    final line = RouteLine(route.points);
    final along = line.snap(position).distanceAlong;
    return estimateArrivalAt(now ?? DateTime.now(), remainingDurationAt(route, along));
  }

  void dispose() {}
}

/// Used when the routing settings are unusable: every request fails as
/// "unavailable", so screens show that instead of a broken route.
class UnavailableRoutingService extends RoutingService {
  const UnavailableRoutingService();

  @override
  Future<RouteResult> getRoute(LatLng origin, LatLng destination, {bool alternatives = true}) async =>
      throw const RoutingException(RoutingFailure.unavailable, 'routing is not configured');
}

/// Arrival time after [remainingSeconds] from [now].
DateTime estimateArrivalAt(DateTime now, double remainingSeconds) => estimateArrival(now, remainingSeconds);

/// Valid coordinates for a routing request.
bool isRoutablePoint(LatLng p) =>
    p.latitude.isFinite && p.longitude.isFinite && p.latitude.abs() <= 90 && p.longitude.abs() <= 180 && !(p.latitude == 0 && p.longitude == 0);

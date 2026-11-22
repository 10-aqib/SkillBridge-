import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/maps_api.dart';

/// Stands in for the maps functions: answers with what a test sets and
/// records every call.
class FakeMapsApi implements MapsApi {
  FakeMapsApi({this.available = true, this.routeResult, this.routeFailure, this.places = const [], this.searchFailure, this.address});

  @override
  bool available;

  RouteSummary? routeResult;
  MapsApiFailure? routeFailure;
  List<MapPlace> places;
  MapsApiFailure? searchFailure;
  MapPlace? address;

  final routes = <(GeoCoord, GeoCoord)>[];
  final searches = <String>[];
  final reverses = <GeoCoord>[];

  @override
  Future<RouteSummary> route(GeoCoord origin, GeoCoord destination) async {
    routes.add((origin, destination));
    if (routeFailure != null) throw MapsApiException(routeFailure!);
    return routeResult ?? RouteSummary(distanceMeters: 4210, durationSeconds: 754, points: [origin, destination]);
  }

  @override
  Future<List<MapPlace>> search(String query, {GeoCoord? near}) async {
    searches.add(query);
    if (searchFailure != null) throw MapsApiException(searchFailure!);
    return places;
  }

  @override
  Future<MapPlace?> reverse(GeoCoord point) async {
    reverses.add(point);
    return address;
  }
}

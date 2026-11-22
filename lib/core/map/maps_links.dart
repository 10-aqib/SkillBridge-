import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Links that open a place or a route in Google Maps, using the documented
/// cross-platform Maps URLs (https://developers.google.com/maps/documentation/urls/get-started).
///
/// On Android and iOS these open the Google Maps app when it is installed,
/// otherwise Google Maps in the browser. They need no API key. Turn-by-turn
/// guidance happens in Google Maps itself; the app never builds its own
/// guidance from Google route data (Google Maps Platform terms).
abstract final class GoogleMapsLinks {
  /// A pin on [point].
  static Uri place(GeoCoord point) =>
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': point.urlValue});

  /// Directions to [destination], from the device's location unless
  /// [origin] is given. [mode] is `driving`, `walking`, `bicycling` or
  /// `two-wheeler`.
  static Uri directions(GeoCoord destination, {GeoCoord? origin, String mode = 'driving'}) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        if (origin != null) 'origin': origin.urlValue,
        'destination': destination.urlValue,
        'travelmode': mode,
      });

  /// Opens [uri] in the Google Maps app or the browser. False when nothing
  /// on the device could open it.
  static Future<bool> open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
    } catch (e) {
      Logger.w('[GoogleMapsLinks] external launch failed: $e');
    }
    try {
      return await launchUrl(uri);
    } catch (e) {
      Logger.w('[GoogleMapsLinks] launch failed: $e');
      return false;
    }
  }
}

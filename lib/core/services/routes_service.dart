import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:skill_bridge/core/services/google_maps_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteResult {
  final List<LatLng> polylinePoints;
  final int distanceMeters;
  final int durationSeconds;

  RouteResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RoutesService {
  static const String _baseUrl = 'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// Fetches driving route between two points using Google Routes API.
  static Future<RouteResult?> getDrivingRoute(LatLng origin, LatLng destination) async {
    try {
      final response = await GoogleMapsService.post(
        _baseUrl,
        headers: {
          // Specify fields to return to reduce payload and billing cost
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
        },
        body: {
          'origin': {
            'location': {
              'latLng': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              }
            }
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              }
            }
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
        },
      );

      final routes = response['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first;
      final polylineStr = route['polyline']?['encodedPolyline'] as String?;
      if (polylineStr == null) return null;

      final distance = route['distanceMeters'] as int? ?? 0;
      
      // Duration is returned as a string like "120s"
      final durationStr = route['duration'] as String? ?? '0s';
      final durationSeconds = int.tryParse(durationStr.replaceAll('s', '')) ?? 0;

      return RouteResult(
        polylinePoints: decodePolyline(polylineStr),
        distanceMeters: distance,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      print('Routes API error: $e');
      return null;
    }
  }

  /// Launches external turn-by-turn navigation (Google Maps or Apple Maps).
  static Future<bool> launchExternalNavigation(double destLat, double destLng) async {
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng';
    final String appleMapsUrl = 'https://maps.apple.com/?daddr=$destLat,$destLng&dirflg=d';

    if (Platform.isIOS) {
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        return await launchUrl(Uri.parse(appleMapsUrl));
      }
    }
    
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      return await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
    }

    print('Could not launch any maps application.');
    return false;
  }

  /// Decodes an encoded polyline string into a list of LatLng points.
  /// (Standard algorithm for decoding Google Maps polylines).
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}

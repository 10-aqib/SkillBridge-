import 'package:skill_bridge/core/services/google_maps_service.dart';

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
  });
}

class GeocodingService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Converts coordinates into a clean formatted address.
  static Future<GeocodingResult?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await GoogleMapsService.get(
        _baseUrl,
        queryParameters: {
          'latlng': '$latitude,$longitude',
        },
        useCache: true, // Reverse geocoding results can be cached safely
      );

      return _parseGeocodingResponse(response);
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Converts address text to coordinates.
  static Future<GeocodingResult?> forwardGeocode(String address) async {
    if (address.isEmpty) return null;
    
    try {
      final response = await GoogleMapsService.get(
        _baseUrl,
        queryParameters: {
          'address': address,
          'components': 'country:PK', // Restrict to Pakistan for SkillBridge
        },
        useCache: true,
      );

      return _parseGeocodingResponse(response);
    } catch (e) {
      print('Forward geocoding error: $e');
      return null;
    }
  }

  static GeocodingResult? _parseGeocodingResponse(dynamic response) {
    if (response['status'] != 'OK') return null;

    final results = response['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final firstResult = results.first;
    
    final geometry = firstResult['geometry']?['location'];
    if (geometry == null) return null;

    final lat = geometry['lat'] as double;
    final lng = geometry['lng'] as double;
    final formattedAddress = firstResult['formatted_address'] as String? ?? '';

    String city = 'Unknown';
    final components = firstResult['address_components'] as List<dynamic>?;
    if (components != null) {
      for (final component in components) {
        final types = component['types'] as List<dynamic>? ?? [];
        if (types.contains('locality')) {
          city = component['long_name'] ?? city;
          break;
        }
      }
    }

    return GeocodingResult(
      latitude: lat,
      longitude: lng,
      formattedAddress: formattedAddress,
      city: city,
    );
  }
}

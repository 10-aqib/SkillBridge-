import 'package:skill_bridge/core/services/google_maps_service.dart';

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final text = json['text']?['text'] ?? '';
    final structured = json['structuredFormat'] ?? {};
    final main = structured['mainText']?['text'] ?? text;
    final secondary = structured['secondaryText']?['text'] ?? '';
    
    return PlacePrediction(
      placeId: json['placeId'] ?? '',
      mainText: main,
      secondaryText: secondary,
    );
  }
}

class PlaceDetails {
  final String placeId;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;

  PlaceDetails({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
  });
}

class PlacesService {
  static const String _baseUrl = 'https://places.googleapis.com/v1/places';

  /// Fetches autocomplete predictions for a given query using the Places API (New).
  /// [sessionToken] should be a UUIDv4 string generated when the user starts typing.
  static Future<List<PlacePrediction>> getAutocompletePredictions(String query, String sessionToken) async {
    if (query.isEmpty) return [];

    try {
      final response = await GoogleMapsService.post(
        '$_baseUrl:autocomplete',
        body: {
          'input': query,
          'sessionToken': sessionToken,
          // Limit search to Pakistan for SkillBridge
          'includedRegionCodes': ['PK'],
        },
      );

      final suggestions = response['suggestions'] as List<dynamic>?;
      if (suggestions == null) return [];

      return suggestions
          .map((s) => s['placePrediction'])
          .where((p) => p != null)
          .map((p) => PlacePrediction.fromJson(p))
          .toList();
    } catch (e) {
      print('Places autocomplete error: $e');
      return [];
    }
  }

  /// Fetches precise details for a place ID using the Places API (New).
  /// Pass the same [sessionToken] used during autocomplete to optimize billing.
  static Future<PlaceDetails?> getPlaceDetails(String placeId, String sessionToken) async {
    try {
      final response = await GoogleMapsService.get(
        '$_baseUrl/$placeId',
        queryParameters: {
          'sessionToken': sessionToken,
          // FieldMask for Places API (New) to specify which fields we want.
          // Location (lat/lng) and formattedAddress are essential.
          'fields': 'id,location,formattedAddress,addressComponents',
        },
        useCache: true, // Details can safely be cached
      );

      final location = response['location'];
      if (location == null) return null;

      final lat = location['latitude'] as double;
      final lng = location['longitude'] as double;
      final formattedAddress = response['formattedAddress'] as String? ?? '';

      // Try to extract city from address components
      String city = 'Unknown';
      final components = response['addressComponents'] as List<dynamic>?;
      if (components != null) {
        for (final component in components) {
          final types = component['types'] as List<dynamic>? ?? [];
          if (types.contains('locality')) {
            city = component['longText'] ?? city;
            break;
          }
        }
      }

      return PlaceDetails(
        placeId: placeId,
        latitude: lat,
        longitude: lng,
        formattedAddress: formattedAddress,
        city: city,
      );
    } catch (e) {
      print('Place details error: $e');
      return null;
    }
  }
}

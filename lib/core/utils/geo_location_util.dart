import 'dart:math' as math;

enum LocationAccuracyLevel {
  high,
  medium,
  low,
  unknown
}

/// Core Geolocation utilities utilizing Haversine distance and real coordinates.
class GeoLocationUtil {
  static const double _earthRadiusKm = 6371.0;

  /// Strict validation for GPS coordinates.
  static bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN) return false;
    if (lat == 0.0 && lng == 0.0) return false; // Common default/error value
    if (lat < -90.0 || lat > 90.0) return false;
    if (lng < -180.0 || lng > 180.0) return false;
    return true;
  }

  /// Evaluates the accuracy level based on meters.
  static LocationAccuracyLevel evaluateAccuracy(double accuracyInMeters) {
    if (accuracyInMeters <= 20.0) return LocationAccuracyLevel.high;
    if (accuracyInMeters <= 50.0) return LocationAccuracyLevel.medium;
    if (accuracyInMeters > 50.0) return LocationAccuracyLevel.low;
    return LocationAccuracyLevel.unknown;
  }

  /// Calculates the surface distance in kilometers between two GPS coordinates
  /// using the Haversine formula.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = _earthRadiusKm * c;

    return double.parse(distance.toStringAsFixed(2));
  }

  /// Calculates estimated driving time in minutes based on average speed.
  static int calculateEtaMinutes(
    double distanceKm, {
    double averageSpeedKmh = 25.0,
  }) {
    if (distanceKm <= 0) return 1;
    final hours = distanceKm / averageSpeedKmh;
    final minutes = (hours * 60).round() + 2; // +2 mins buffer for city traffic
    return math.max(1, minutes);
  }

  /// Formats distance (meters if < 1 km, e.g. "800 m", km otherwise e.g. "1.4 km").
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    } else {
      final kmStr = distanceKm.toStringAsFixed(1);
      return '$kmStr km';
    }
  }
  
  /// (Deprecated/Legacy) Formats inDrive-style Distance string
  static String formatInDriveDistance(double distanceKm, {bool isUrdu = false}) {
    return formatDistance(distanceKm);
  }

  /// Formats Distance & ETA string (e.g. "800 m • ~3 min away").
  static String formatInDriveDistanceEta(double distanceKm, {bool isUrdu = false}) {
    final distStr = formatDistance(distanceKm);
    final eta = calculateEtaMinutes(distanceKm);
    return '$distStr • ~$eta min away';
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}

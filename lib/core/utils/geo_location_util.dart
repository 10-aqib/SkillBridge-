import 'dart:math' as math;

/// Represents a geofenced Pakistani locality with coordinates and city.
class PakistaniLocality {
  final String name;
  final String city;
  final String urduName;
  final double latitude;
  final double longitude;
  final double radiusKm;

  const PakistaniLocality({
    required this.name,
    required this.city,
    required this.urduName,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 3.5,
  });
}

/// Geolocation and Geofencing utility tailored for Pakistani cities
/// (Lahore, Karachi, Islamabad) with Haversine distance and city traffic ETA.
class GeoLocationUtil {
  static const double _earthRadiusKm = 6371.0;

  /// Built-in Pakistani major localities for geofencing & address matching.
  static const List<PakistaniLocality> pakistaniLocalities = [
    PakistaniLocality(
      name: 'Gulberg III',
      city: 'Lahore',
      urduName: 'گلبرگ 3، لاہور',
      latitude: 31.5102,
      longitude: 74.3441,
    ),
    PakistaniLocality(
      name: 'DHA Phase 5',
      city: 'Lahore',
      urduName: 'ڈی ایچ اے فیز 5، لاہور',
      latitude: 31.4697,
      longitude: 74.4093,
    ),
    PakistaniLocality(
      name: 'Johar Town',
      city: 'Lahore',
      urduName: 'جوہرتائون، لاہور',
      latitude: 31.4697,
      longitude: 74.2965,
    ),
    PakistaniLocality(
      name: 'Bahria Town',
      city: 'Lahore',
      urduName: 'بحریہ ٹائون، لاہور',
      latitude: 31.3653,
      longitude: 74.1770,
    ),
    PakistaniLocality(
      name: 'Model Town',
      city: 'Lahore',
      urduName: 'ماڈل ٹائون، لاہور',
      latitude: 31.4826,
      longitude: 74.3262,
    ),
    PakistaniLocality(
      name: 'Clifton Block 4',
      city: 'Karachi',
      urduName: 'کلفٹن بلاک 4، کراچی',
      latitude: 24.8138,
      longitude: 67.0300,
    ),
    PakistaniLocality(
      name: 'F-10 Markaz',
      city: 'Islamabad',
      urduName: 'ایف 10 مرکز، اسلام آباد',
      latitude: 33.6938,
      longitude: 73.0111,
    ),
  ];

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

  /// Calculates estimated driving time in minutes based on Pakistani city
  /// traffic conditions (default average speed 25 km/h + 2 mins parking buffer).
  static int calculateEtaMinutes(
    double distanceKm, {
    double averageSpeedKmh = 25.0,
  }) {
    if (distanceKm <= 0) return 1;
    final hours = distanceKm / averageSpeedKmh;
    final minutes = (hours * 60).round() + 2; // +2 mins buffer for city traffic
    return math.max(1, minutes);
  }

  /// Detects the closest Pakistani locality from GPS coordinates.
  /// Returns standard formatted string `"Locality, City • اردو نام"`.
  static String detectLocality(double lat, double lon) {
    PakistaniLocality? closest;
    double minDistance = double.infinity;

    for (final loc in pakistaniLocalities) {
      final dist = calculateDistanceKm(lat, lon, loc.latitude, loc.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        closest = loc;
      }
    }

    if (closest != null && minDistance <= 15.0) {
      return '${closest.name}, ${closest.city} • ${closest.urduName}';
    }

    return 'Lahore City • لاہور شہر';
  }

  /// Formats distance in inDrive style (meters if < 1 km, e.g. "800 m", km otherwise e.g. "1.4 km").
  static String formatInDriveDistance(double distanceKm, {bool isUrdu = false}) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return isUrdu ? '$meters میٹر' : '$meters m';
    } else {
      final kmStr = distanceKm.toStringAsFixed(1);
      return isUrdu ? '$kmStr کلومیٹر' : '$kmStr km';
    }
  }

  /// Formats inDrive-style Distance & ETA string (e.g., "800 m • ~3 min away" or Urdu equivalent).
  static String formatInDriveDistanceEta(double distanceKm, {bool isUrdu = false}) {
    final distStr = formatInDriveDistance(distanceKm, isUrdu: isUrdu);
    final eta = calculateEtaMinutes(distanceKm);
    return isUrdu ? '$distStr • ~$eta منٹ دور' : '$distStr • ~$eta min away';
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}


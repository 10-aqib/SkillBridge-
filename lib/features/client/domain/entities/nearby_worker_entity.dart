import 'dart:math';

class GeoPointLocation {
  final double latitude;
  final double longitude;

  const GeoPointLocation({
    required this.latitude,
    required this.longitude,
  });

  /// Calculates the Haversine distance in kilometers between two geo points.
  double distanceTo(GeoPointLocation other) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(other.latitude - latitude);
    double dLon = _degreesToRadians(other.longitude - longitude);

    double lat1Rad = _degreesToRadians(latitude);
    double lat2Rad = _degreesToRadians(other.latitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class NearbyWorkerEntity {
  final String workerId;
  final String name;
  final String category;
  final double hourlyRate;
  final double rating;
  final String? profilePicture;
  final GeoPointLocation location;
  final double distanceKm;
  final bool isAvailable;
  final double matchScore;

  NearbyWorkerEntity({
    required this.workerId,
    required this.name,
    required this.category,
    required this.hourlyRate,
    required this.rating,
    this.profilePicture,
    required this.location,
    required this.distanceKm,
    this.isAvailable = true,
    this.matchScore = 0.0,
  });

  NearbyWorkerEntity copyWith({
    String? workerId,
    String? name,
    String? category,
    double? hourlyRate,
    double? rating,
    String? profilePicture,
    GeoPointLocation? location,
    double? distanceKm,
    bool? isAvailable,
    double? matchScore,
  }) {
    return NearbyWorkerEntity(
      workerId: workerId ?? this.workerId,
      name: name ?? this.name,
      category: category ?? this.category,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      profilePicture: profilePicture ?? this.profilePicture,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      isAvailable: isAvailable ?? this.isAvailable,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}

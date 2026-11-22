import 'dart:math' as math;

/// A latitude/longitude pair that belongs to no map SDK, so domain code,
/// models and tests don't depend on whichever map package draws them.
///
/// Map widgets convert at their edge (for Google Maps: `LatLng`).
class GeoCoord {
  const GeoCoord(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Finite, within range, and not the (0, 0) "null island" placeholder
  /// that missing data often turns into.
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  /// Straight-line (great-circle) distance in metres. For filtering and
  /// "about X away"; never shown as a road distance.
  double metresTo(GeoCoord other) => distanceMetres(this, other);

  /// `lat,lng` with six decimals (about 10 cm), as map links expect.
  String get urlValue => '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

  @override
  bool operator ==(Object other) => other is GeoCoord && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoCoord(${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)})';
}

const _earthRadiusMetres = 6371008.8;

double _rad(double deg) => deg * math.pi / 180;

/// Haversine distance in metres between [a] and [b].
double distanceMetres(GeoCoord a, GeoCoord b) {
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMetres * math.asin(math.min(1, math.sqrt(h)));
}

/// Bearing in degrees (0–360) from [a] to [b], for fixes without a heading.
double bearingBetween(GeoCoord a, GeoCoord b) {
  final lat1 = _rad(a.latitude), lat2 = _rad(b.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

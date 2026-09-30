import 'dart:math' as math;

/// Pure Dart implementation of Base32 Geohash for Firestore spatial queries.
class GeohashUtil {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a latitude and longitude into a geohash string.
  static String encode(double latitude, double longitude, {int precision = 9}) {
    bool isEven = true;
    double minLat = -90.0, maxLat = 90.0;
    double minLng = -180.0, maxLng = 180.0;
    int bit = 0;
    int ch = 0;
    String hash = '';

    while (hash.length < precision) {
      if (isEven) {
        double mid = (minLng + maxLng) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        double mid = (minLat + maxLat) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        hash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    return hash;
  }

  /// Calculates the bounding box for a given center coordinate and radius in kilometers.
  /// Returns [minLat, minLng, maxLat, maxLng].
  static List<double> _boundingBox(double latitude, double longitude, double radiusKm) {
    // 1 degree of latitude is ~111.32 km
    const double latPerKm = 1.0 / 111.32;
    double latDelta = radiusKm * latPerKm;
    double minLat = latitude - latDelta;
    double maxLat = latitude + latDelta;

    // Longitude varies with latitude
    double lngDelta = radiusKm * latPerKm / math.cos(latitude * math.pi / 180.0);
    double minLng = longitude - lngDelta;
    double maxLng = longitude + lngDelta;

    return [minLat, minLng, maxLat, maxLng];
  }

  /// Calculates a simplified geohash bounding range for Firestore queries.
  /// Note: Real spatial queries often require multiple contiguous ranges,
  /// but this provides a simple continuous prefix range based on the bounding box.
  static List<String> getGeohashRange(double latitude, double longitude, double radiusKm) {
    final bounds = _boundingBox(latitude, longitude, radiusKm);
    
    // Calculate the bits required to cover the bounding box
    final minLat = bounds[0];
    final minLng = bounds[1];
    final maxLat = bounds[2];
    final maxLng = bounds[3];

    // Encode the SW and NE corners
    String sw = encode(minLat, minLng, precision: 9);
    String ne = encode(maxLat, maxLng, precision: 9);

    // Find the common prefix
    int i = 0;
    while (i < sw.length && i < ne.length && sw[i] == ne[i]) {
      i++;
    }
    
    String prefix = sw.substring(0, i);
    
    // If the prefix is too short, we just use a basic range covering the area.
    // In practice, for a query: where('geohash', isGreaterThanOrEqualTo: lower).where('geohash', isLessThanOrEqualTo: upper)
    String lower = prefix;
    String upper = prefix + '~'; // '~' is high in ascii

    return [lower, upper];
  }
}

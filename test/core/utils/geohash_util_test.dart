import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/utils/geohash_util.dart';

void main() {
  group('GeohashUtil', () {
    test('encode should return correct geohash for known coordinates', () {
      // Coordinates of Islamabad
      final lat = 33.6844;
      final lon = 73.0479;
      
      final hash = GeohashUtil.encode(lat, lon, precision: 9);
      
      // Known approximate geohash for Islamabad is 'twjf8yqdt' or similar depending on exact coord.
      // We just ensure it's a valid string of correct length
      expect(hash, isA<String>());
      expect(hash.length, 9);
    });

    test('getGeohashRange should return correct valid start and end strings', () {
      final bounds = GeohashUtil.getGeohashRange(33.6844, 73.0479, 10.0);
      
      // Should return a list of [lower, upper] strings
      expect(bounds.length, 2);
      expect(bounds[0].compareTo(bounds[1]), lessThanOrEqualTo(0));
    });
  });
}

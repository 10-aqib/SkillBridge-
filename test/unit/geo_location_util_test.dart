import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';

void main() {
  group('GeoLocationUtil', () {
    test('calculateDistanceKm computes accurate Haversine distance', () {
      // Gulberg III (31.5102, 74.3441) to DHA Phase 5 (31.4697, 74.4093) in Lahore
      final dist = GeoLocationUtil.calculateDistanceKm(
        31.5102,
        74.3441,
        31.4697,
        74.4093,
      );

      // Should be around 7.7 - 7.9 km
      expect(dist, greaterThan(7.0));
      expect(dist, lessThan(8.5));
    });

    test('calculateDistanceKm returns 0 for identical coordinates', () {
      final dist = GeoLocationUtil.calculateDistanceKm(
        31.5102,
        74.3441,
        31.5102,
        74.3441,
      );
      expect(dist, equals(0.0));
    });

    test('calculateEtaMinutes calculates Lahore traffic ETA with buffer', () {
      // 5.0 km at 25 km/h => 12 mins + 2 mins buffer = 14 mins
      final eta = GeoLocationUtil.calculateEtaMinutes(5.0);
      expect(eta, equals(14));
    });

    test('calculateEtaMinutes returns minimum 1 min for 0 km', () {
      final eta = GeoLocationUtil.calculateEtaMinutes(0.0);
      expect(eta, equals(1));
    });

    test('detectLocality matches closest Pakistani neighborhood', () {
      // Coordinates near Gulberg III (31.5100, 74.3440)
      final loc1 = GeoLocationUtil.detectLocality(31.5100, 74.3440);
      expect(loc1, contains('Gulberg III, Lahore'));
      expect(loc1, contains('گلبرگ'));

      // Coordinates near DHA Phase 5 (31.4700, 74.4090)
      final loc2 = GeoLocationUtil.detectLocality(31.4700, 74.4090);
      expect(loc2, contains('DHA Phase 5, Lahore'));
    });

    test('formatInDriveDistance formats meters when under 1 km and km when 1 km or above', () {
      expect(GeoLocationUtil.formatInDriveDistance(0.45), equals('450 m'));
      expect(GeoLocationUtil.formatInDriveDistance(0.45, isUrdu: true), equals('450 میٹر'));
      expect(GeoLocationUtil.formatInDriveDistance(1.84), equals('1.8 km'));
      expect(GeoLocationUtil.formatInDriveDistance(1.84, isUrdu: true), equals('1.8 کلومیٹر'));
    });

    test('formatInDriveDistanceEta includes formatted distance and estimated arrival time', () {
      expect(GeoLocationUtil.formatInDriveDistanceEta(0.8), contains('800 m • ~'));
      expect(GeoLocationUtil.formatInDriveDistanceEta(0.8, isUrdu: true), contains('800 میٹر • ~'));
      expect(GeoLocationUtil.formatInDriveDistanceEta(2.4), contains('2.4 km • ~'));
    });
  });
}


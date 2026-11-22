import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/maps_api.dart';
import 'package:skill_bridge/core/map/route_format.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/test_app.dart';

void main() {
  group('decodePolyline', () {
    test("decodes Google's documented example", () {
      // https://developers.google.com/maps/documentation/utilities/polylinealgorithm
      final pts = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(pts, hasLength(3));
      expect(pts[0].latitude, closeTo(38.5, 1e-9));
      expect(pts[0].longitude, closeTo(-120.2, 1e-9));
      expect(pts[1].latitude, closeTo(40.7, 1e-9));
      expect(pts[1].longitude, closeTo(-120.95, 1e-9));
      expect(pts[2].latitude, closeTo(43.252, 1e-9));
      expect(pts[2].longitude, closeTo(-126.453, 1e-9));
    });

    test('empty is no points; a truncated line is refused', () {
      expect(decodePolyline(''), isEmpty);
      expect(() => decodePolyline('_p~iF~ps|U_'), throwsFormatException);
    });
  });

  group('FunctionsMapsApi without Firebase', () {
    test('is simply not available (no crash), and stays off for the session', () async {
      final api = FunctionsMapsApi(() => throw StateError('no Firebase app'));
      expect(api.available, isTrue);
      await expectLater(api.route(const GeoCoord(31.52, 74.35), const GeoCoord(31.55, 74.34)),
          throwsA(isA<MapsApiException>().having((e) => e.failure, 'failure', MapsApiFailure.notAvailable)));
      expect(api.available, isFalse);
      await expectLater(api.search('liberty'), throwsA(isA<MapsApiException>()));
    });

    test('invalid input is refused before any call', () async {
      var asked = 0;
      final api = FunctionsMapsApi(() {
        asked++;
        throw StateError('x');
      });
      await expectLater(api.route(const GeoCoord(0, 0), const GeoCoord(31.5, 74.3)),
          throwsA(isA<MapsApiException>().having((e) => e.failure, 'failure', MapsApiFailure.invalid)));
      await expectLater(api.search('ab'), throwsA(isA<MapsApiException>().having((e) => e.failure, 'failure', MapsApiFailure.invalid)));
      expect(asked, 0);
      expect(api.available, isTrue);
    });
  });

  group('route formatting', () {
    late AppLocalizations l;
    setUpAll(() async => l = await englishStrings());

    test('distance: metres in steps, then kilometres', () {
      expect(formatRouteDistance(l, 87), l.navMeters(90));
      expect(formatRouteDistance(l, 640), l.navMeters(650));
      expect(formatRouteDistance(l, 4210), l.navKilometres('4.2'));
      expect(formatRouteDistance(l, 23456), l.navKilometres('23'));
    });

    test('time: rounded up to the minute, hours past 60', () {
      expect(formatRouteDuration(l, 20), l.navUnderAMinute);
      expect(formatRouteDuration(l, 754), l.navMinutes(13));
      expect(formatRouteDuration(l, 3600 + 125), l.navHoursMinutes(1, 3));
    });
  });
}

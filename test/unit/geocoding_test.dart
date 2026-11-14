import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/map/geocoding.dart';
import 'package:skill_bridge/core/map/map_config.dart';

/// Shapes copied from real Nominatim jsonv2 answers (Lahore).
const _searchBody = [
  {
    'lat': '31.5880838',
    'lon': '74.3107282',
    'name': 'Badshahi Mosque',
    'display_name': 'Badshahi Mosque, Fort Road, Walled City, Lahore, Punjab, 54000, Pakistan',
    'address': {'amenity': 'Badshahi Mosque', 'road': 'Fort Road', 'city': 'Lahore', 'state': 'Punjab', 'country': 'Pakistan'},
  },
  {'lat': 'not a number', 'lon': '74.3', 'display_name': 'broken'},
];
const _reverseBody = {
  'lat': '31.5925',
  'lon': '74.3095',
  'name': '',
  'display_name': 'Minar-e-Pakistan, Circular Road, Lahore, Punjab, Pakistan',
  'address': {'town': 'Lahore Cantonment'},
};

void main() {
  final config = GeocodingConfig.fromValues(provider: 'nominatim', baseUrl: 'https://geo.example.com/');

  NominatimGeocodingService service(MockClient client) =>
      NominatimGeocodingService(config, client: client, minGap: Duration.zero);

  test('search asks once, with the policy-required parameters, and parses usable results', () async {
    final asked = <http.Request>[];
    final geo = service(MockClient((r) async {
      asked.add(r);
      return http.Response(jsonEncode(_searchBody), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final places = await geo.search('  badshahi   mosque ');
    expect(places, hasLength(1), reason: 'the result without a valid position is dropped');
    expect(places.single.name, 'Badshahi Mosque');
    expect(places.single.city, 'Lahore');
    expect(places.single.point.latitude, closeTo(31.5880838, 1e-9));

    final q = asked.single.url;
    expect(q.host, 'geo.example.com');
    expect(q.path, '/search');
    expect(q.queryParameters['q'], 'badshahi mosque');
    expect(q.queryParameters['format'], 'jsonv2');
    expect(q.queryParameters['countrycodes'], 'pk');
    expect(q.queryParameters['limit'], '5');
    expect(asked.single.headers['User-Agent'], contains('com.skillbridge.skill_bridge'), reason: 'apps must identify themselves');

    await geo.search('Badshahi Mosque');
    expect(asked, hasLength(1), reason: 'the same search is answered from the cache');
  });

  test('queries shorter than 3 characters never reach the server', () async {
    var calls = 0;
    final geo = service(MockClient((r) async {
      calls++;
      return http.Response('[]', 200);
    }));
    expect(await geo.search('ab'), isEmpty);
    expect(calls, 0);
  });

  test('requests are spaced at least minGap apart (≤ 1 per second by default)', () async {
    final times = <DateTime>[];
    final geo = NominatimGeocodingService(config, minGap: const Duration(milliseconds: 150), client: MockClient((r) async {
      times.add(DateTime.now());
      return http.Response('[]', 200);
    }));
    await Future.wait([geo.search('first place'), geo.search('second place'), geo.search('third place')]);
    expect(times, hasLength(3));
    for (var i = 1; i < times.length; i++) {
      expect(times[i].difference(times[i - 1]).inMilliseconds, greaterThanOrEqualTo(140));
    }
    expect(NominatimGeocodingService(config).minGap, const Duration(seconds: 1));
  });

  test('a refusal or a broken answer is "unavailable"; no connection is "network"', () async {
    Future<GeocodingFailure?> failure(MockClient c) async {
      try {
        await service(c).search('anything here');
        return null;
      } on GeocodingException catch (e) {
        return e.failure;
      }
    }

    expect(await failure(MockClient((r) async => http.Response('slow down', 429))), GeocodingFailure.unavailable);
    expect(await failure(MockClient((r) async => http.Response('<html>', 200))), GeocodingFailure.unavailable);
    expect(await failure(MockClient((r) async => throw const SocketException('offline'))), GeocodingFailure.network);
  });

  test('reverse gives the address, falls back through town names, and never throws', () async {
    var calls = 0;
    final geo = service(MockClient((r) async {
      calls++;
      expect(r.url.path, '/reverse');
      return http.Response(jsonEncode(_reverseBody), 200);
    }));
    final p = await geo.reverse(const LatLng(31.5925, 74.3095));
    expect(p!.label, startsWith('Minar-e-Pakistan'));
    expect(p.name, 'Minar-e-Pakistan', reason: 'no name: first part of the address');
    expect(p.city, 'Lahore Cantonment');
    await geo.reverse(const LatLng(31.592500004, 74.309500004));
    expect(calls, 1, reason: 'the same spot (to about 1 m) is cached');

    final down = service(MockClient((r) async => throw const SocketException('offline')));
    expect(await down.reverse(const LatLng(31.5, 74.3)), isNull);
    final nothing = service(MockClient((r) async => http.Response('{"error":"Unable to geocode"}', 200)));
    expect(await nothing.reverse(const LatLng(0, 0)), isNull);
  });

  test('with search switched off nothing is requested', () async {
    const none = NoGeocodingService();
    expect(none.searchEnabled, isFalse);
    expect(await none.search('Lahore'), isEmpty);
    expect(await none.reverse(const LatLng(31.5, 74.3)), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/map/map_config.dart';

void main() {
  group('MapTileConfig', () {
    test('defaults to public OSM tiles with the required attribution', () {
      final c = MapTileConfig.fromValues();
      expect(c.urlTemplate, MapTileConfig.defaultUrlTemplate);
      expect(c.attribution, contains('OpenStreetMap'));
      expect(c.attributionUrl, startsWith('https://'));
      expect(c.isValid, isTrue);
      expect(c.isPublicOsm, isTrue);
    });

    test('tests run without dart-defines, so the environment gives the defaults', () {
      expect(MapTileConfig.fromEnvironment().urlTemplate, MapTileConfig.defaultUrlTemplate);
      expect(RoutingConfig.fromEnvironment().baseUrl, RoutingConfig.defaultBaseUrl);
      expect(GeocodingConfig.fromEnvironment().provider, GeocodingProvider.nominatim);
    });

    test('blank values (a copied .env.example) mean the defaults', () {
      final c = MapTileConfig.fromValues(urlTemplate: '  ', attribution: '', maxZoom: ' ');
      expect(c.urlTemplate, MapTileConfig.defaultUrlTemplate);
      expect(c.maxZoom, 19);
    });

    test('a custom provider with subdomains is accepted', () {
      final c = MapTileConfig.fromValues(
        urlTemplate: 'https://{s}.tiles.example.com/{z}/{x}/{y}{r}.png',
        subdomains: 'a, b ,c',
        attribution: '© Example, © OpenStreetMap contributors',
        maxZoom: '20',
      );
      expect(c.subdomains, ['a', 'b', 'c']);
      expect(c.maxZoom, 20);
      expect(c.isValid, isTrue);
      expect(c.isPublicOsm, isFalse);
    });

    test('bad templates are refused', () {
      for (final t in [
        'https://tiles.example.com/{z}/{x}.png', // no {y}
        'http://tiles.example.com/{z}/{x}/{y}.png', // plain http to a remote host
        'ftp://tiles.example.com/{z}/{x}/{y}.png',
        'tiles/{z}/{x}/{y}.png', // no host
      ]) {
        expect(MapTileConfig.fromValues(urlTemplate: t).isValid, isFalse, reason: t);
      }
      expect(MapTileConfig.fromValues(urlTemplate: 'https://{s}.t.example.com/{z}/{x}/{y}.png').isValid, isFalse,
          reason: '{s} without subdomains');
    });

    test('plain http is allowed only for a local development server', () {
      expect(MapTileConfig.fromValues(urlTemplate: 'http://localhost:8080/{z}/{x}/{y}.png').isValid, isTrue);
      expect(MapTileConfig.fromValues(urlTemplate: 'http://10.0.2.2:8080/{z}/{x}/{y}.png').isValid, isTrue);
    });

    test('max zoom is clamped', () {
      expect(MapTileConfig.fromValues(maxZoom: '40').maxZoom, 22);
      expect(MapTileConfig.fromValues(maxZoom: 'x').maxZoom, 19);
    });
  });

  group('RoutingConfig', () {
    test('defaults to the public OSRM demo, flagged as such', () {
      final c = RoutingConfig.fromValues();
      expect(c.baseUrl, 'https://router.project-osrm.org');
      expect(c.profile, 'driving');
      expect(c.isValid, isTrue);
      expect(c.isPublicDemo, isTrue);
    });

    test('a self-hosted server replaces it; trailing slashes are dropped', () {
      final c = RoutingConfig.fromValues(baseUrl: 'https://osrm.example.com/', profile: 'cycling');
      expect(c.baseUrl, 'https://osrm.example.com');
      expect(c.isValid, isTrue);
      expect(c.isPublicDemo, isFalse);
    });

    test('bad addresses and profiles are refused', () {
      expect(RoutingConfig.fromValues(baseUrl: 'http://osrm.example.com').isValid, isFalse);
      expect(RoutingConfig.fromValues(baseUrl: 'not a url').isValid, isFalse);
      expect(RoutingConfig.fromValues(profile: 'driving/../x').isValid, isFalse);
    });
  });

  group('GeocodingConfig', () {
    test('defaults to submit-only Nominatim search limited to Pakistan', () {
      final c = GeocodingConfig.fromValues();
      expect(c.provider, GeocodingProvider.nominatim);
      expect(c.countryCodes, 'pk');
      expect(c.searchEnabled, isTrue);
    });

    test('release builds never fall back to the public server', () {
      expect(GeocodingConfig.fromValues(releaseBuild: true).searchEnabled, isFalse);
      expect(GeocodingConfig.fromValues(provider: 'nominatim', releaseBuild: true).searchEnabled, isTrue,
          reason: 'an explicit choice is respected');
      final own = GeocodingConfig.fromValues(provider: 'nominatim', baseUrl: 'https://geo.example.com', releaseBuild: true);
      expect(own.searchEnabled, isTrue);
      expect(own.isPublicNominatim, isFalse);
    });

    test('"none" turns search off (map pick only)', () {
      expect(GeocodingConfig.fromValues(provider: 'none').searchEnabled, isFalse);
      expect(GeocodingConfig.fromValues(provider: 'OFF').searchEnabled, isFalse);
    });

    test('an unusable address turns search off instead of failing later', () {
      expect(GeocodingConfig.fromValues(baseUrl: 'http://geo.example.com').searchEnabled, isFalse);
    });
  });
}

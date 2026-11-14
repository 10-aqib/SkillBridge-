import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/map/geocoding.dart';
import 'package:skill_bridge/core/map/map_config.dart';
import 'package:skill_bridge/core/map/map_markers.dart';
import 'package:skill_bridge/core/map/sb_map.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/services/location_service.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/live_location_ui.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/widgets/location_picker_screen.dart';

import '../helpers/fake_map_tiles.dart';
import '../helpers/test_app.dart';

const _lahore = LatLng(31.5204, 74.3587);

/// The current-location dot pulses forever, so tests pump fixed steps
/// instead of pumpAndSettle.
Future<void> settle(WidgetTester tester, [int steps = 12]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class FakeGeocoding implements GeocodingService {
  FakeGeocoding({this.enabled = true, this.places = const [], this.address, this.fail = false});
  final bool enabled;
  final List<GeocodedPlace> places;
  final GeocodedPlace? address;
  final bool fail;
  final searches = <String>[];
  final reverses = <LatLng>[];

  @override
  bool get searchEnabled => enabled;

  @override
  Future<List<GeocodedPlace>> search(String query) async {
    searches.add(query);
    if (fail) throw const GeocodingException(GeocodingFailure.network);
    return places;
  }

  @override
  Future<GeocodedPlace?> reverse(LatLng point) async {
    reverses.add(point);
    return address;
  }

  @override
  void dispose() {}
}

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  group('SbMap', () {
    testWidgets('draws tiles from the configured server and always shows the attribution', (tester) async {
      final asked = <String>[];
      await tester.pumpWidget(testApp(
        mapTiles: () => FakeTileProvider(requested: asked),
        home: const Scaffold(body: SbMap(initialCenter: _lahore, initialZoom: 14)),
      ));
      await settle(tester);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text(MapTileConfig.defaultAttribution), findsOneWidget);
      expect(asked, isNotEmpty);
      expect(asked.first, startsWith('https://tile.openstreetmap.org/14/'));
    });

    testWidgets('a bad tile configuration shows "map unavailable" instead of a broken map', (tester) async {
      await tester.pumpWidget(testApp(
        overrides: [mapTileConfigProvider.overrideWithValue(MapTileConfig.fromValues(urlTemplate: 'http://tiles.example.com/{z}/{x}/{y}.png'))],
        home: const Scaffold(body: SbMap(initialCenter: _lahore)),
      ));
      await settle(tester, 2);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text(l.mapUnavailableTitle), findsOneWidget);
    });

    testWidgets('offline shows a notice over the map; online does not', (tester) async {
      for (final online in [false, true]) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(testApp(
          overrides: [connectivityStatusProvider.overrideWith((ref) => Stream.value(online))],
          home: const Scaffold(body: SbMap(initialCenter: _lahore)),
        ));
        await settle(tester, 3);
        expect(find.text(l.mapOffline), online ? findsNothing : findsOneWidget);
      }
    });

    testWidgets('the recenter button appears only when a screen handles it, and calls it', (tester) async {
      var recentered = 0;
      await tester.pumpWidget(testApp(home: Scaffold(body: SbMap(initialCenter: _lahore, onRecenter: () => recentered++))));
      await settle(tester, 3);
      await tester.tap(find.byTooltip(l.mapRecenter));
      expect(recentered, 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(testApp(home: const Scaffold(body: SbMap(initialCenter: _lahore, interactive: false))));
      await settle(tester, 3);
      expect(find.byTooltip(l.mapRecenter), findsNothing, reason: 'previews have no controls');
    });

    testWidgets('dark theme draws the map with markers without errors', (tester) async {
      await tester.pumpWidget(testApp(
        brightness: Brightness.dark,
        home: Scaffold(
          body: SbMap(initialCenter: _lahore, layers: [
            MarkerLayer(markers: [
              sbCurrentLocationMarker(_lahore, heading: 90),
              sbDestinationMarker(const LatLng(31.53, 74.36)),
              sbPersonMarker(const LatLng(31.51, 74.35), name: 'Bilal', stale: true),
            ]),
          ]),
        ),
      ));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(SbCurrentLocationDot), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('LocationPickerScreen', () {
    Future<LocationResult?> openPicker(
      WidgetTester tester, {
      required PickerLocator locator,
      GeocodingService? geo,
      LatLng? initial,
    }) async {
      LocationResult? result;
      await tester.pumpWidget(testApp(
        overrides: [geocodingServiceProvider.overrideWithValue(geo ?? FakeGeocoding(enabled: false))],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<LocationResult>(
                    MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: locator, initialLocation: initial)),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester, 15);
      return result;
    }

    Future<({LatLng point, double accuracy})> here() async => (point: _lahore, accuracy: 8.0);

    testWidgets('locates the device and confirms that spot with its GPS accuracy and address', (tester) async {
      final geo = FakeGeocoding(address: const GeocodedPlace(point: _lahore, label: 'Mall Road, Lahore, Punjab, Pakistan', city: 'Lahore'));
      LocationResult? result;
      await tester.pumpWidget(testApp(
        overrides: [geocodingServiceProvider.overrideWithValue(geo)],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push<LocationResult>(
              MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: here)),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester, 15);

      expect(find.text('Mall Road, Lahore, Punjab, Pakistan'), findsOneWidget);
      expect(find.text(l.liveAccuracy(8)), findsOneWidget);
      expect(geo.reverses, isNotEmpty);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(_lahore.latitude, 1e-6));
      expect(result!.city, 'Lahore');
      expect(result!.formattedAddress, 'Mall Road, Lahore, Punjab, Pakistan');
      expect(result!.accuracy, LocationAccuracyLevel.high);
    });

    testWidgets('without address search the pin still works: coordinates as the address, no search box', (tester) async {
      LocationResult? result;
      await tester.pumpWidget(testApp(
        overrides: [geocodingServiceProvider.overrideWithValue(FakeGeocoding(enabled: false))],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push<LocationResult>(
              MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: here)),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester, 15);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(l.pickerPinnedLocation), findsWidgets);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result!.formattedAddress, '31.52040, 74.35870');
      expect(result!.city, '');
    });

    for (final (name, error, message, action) in [
      ('denied', LocationServiceException('x', isPermissionDenied: true), 'pickerLocationDenied', 'tryAgain'),
      ('blocked', LocationServiceException('x', isSettingsRequired: true), 'pickerLocationBlocked', 'liveOpenSettings'),
      ('GPS off', LocationServiceException('x', isServiceDisabled: true), 'pickerLocationServiceOff', 'liveOpenSettings'),
      ('timeout', LocationServiceException('x'), 'pickerLocationFailed', 'tryAgain'),
    ]) {
      testWidgets('location $name: explained, the map stays usable, and nothing is confirmed at country zoom', (tester) async {
        await openPicker(tester, locator: () async => throw error);
        final texts = {
          'pickerLocationDenied': l.pickerLocationDenied,
          'pickerLocationBlocked': l.pickerLocationBlocked,
          'pickerLocationServiceOff': l.pickerLocationServiceOff,
          'pickerLocationFailed': l.pickerLocationFailed,
          'tryAgain': l.tryAgain,
          'liveOpenSettings': l.liveOpenSettings,
        };
        expect(find.text(texts[message]!), findsOneWidget);
        expect(find.text(texts[action]!), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        final confirm = tester.widget<ButtonStyleButton>(
          find.ancestor(of: find.text(l.pickerConfirm), matching: find.bySubtype<ButtonStyleButton>()).first,
        );
        expect(confirm.onPressed, isNull, reason: 'the whole-country view is not a place');
      });
    }

    testWidgets('search runs on submit only, and choosing a result confirms that place', (tester) async {
      final mosque = const GeocodedPlace(point: LatLng(31.5881, 74.3107), name: 'Badshahi Mosque', label: 'Badshahi Mosque, Fort Road, Lahore', city: 'Lahore');
      final geo = FakeGeocoding(places: [mosque]);
      LocationResult? result;
      await tester.pumpWidget(testApp(
        overrides: [geocodingServiceProvider.overrideWithValue(geo)],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push<LocationResult>(
              MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: here)),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester, 15);

      await tester.enterText(find.byType(TextField), 'badshahi');
      await settle(tester, 3);
      expect(geo.searches, isEmpty, reason: 'no autocomplete');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester, 5);
      expect(geo.searches, ['badshahi']);
      expect(find.text(l.pickerSearchAttribution), findsOneWidget);

      await tester.tap(find.text('Badshahi Mosque'));
      await settle(tester, 15);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result!.latitude, closeTo(31.5881, 1e-4));
      expect(result!.formattedAddress, 'Badshahi Mosque, Fort Road, Lahore');
      expect(result!.accuracy, LocationAccuracyLevel.unknown, reason: 'not the GPS position');
    });

    testWidgets('the location notice goes away once a place is chosen another way', (tester) async {
      final geo = FakeGeocoding(places: [const GeocodedPlace(point: LatLng(31.5881, 74.3107), name: 'Badshahi Mosque', label: 'Badshahi Mosque, Lahore')]);
      await openPicker(tester, locator: () async => throw LocationServiceException('x', isPermissionDenied: true), geo: geo);
      expect(find.text(l.pickerLocationDenied), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'badshahi');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester, 5);
      await tester.tap(find.text('Badshahi Mosque'));
      await settle(tester, 15);
      expect(find.text(l.pickerLocationDenied), findsNothing);
      expect(find.text('Badshahi Mosque, Lahore'), findsOneWidget);
    });

    testWidgets('search problems are explained: too short, nothing found, service down', (tester) async {
      for (final (geo, query, expected) in [
        (FakeGeocoding(), 'ab', l.pickerSearchTooShort),
        (FakeGeocoding(), 'nowhere at all', l.pickerSearchNoResults),
        (FakeGeocoding(fail: true), 'lahore', l.pickerSearchFailed),
      ]) {
        await openPicker(tester, locator: here, geo: geo);
        await tester.enterText(find.byType(TextField), query);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await settle(tester, 5);
        expect(find.text(expected), findsOneWidget, reason: query);
        await tester.pageBack();
        await settle(tester, 5);
      }
    });
  });

  group('maps app link', () {
    test('Android opens any maps app, iOS Apple Maps, web OpenStreetMap; never Google-only', () {
      expect(LiveLocationMap.mapsLink(31.52, 74.35, platform: TargetPlatform.android, web: false).toString(),
          'geo:31.520000,74.350000?q=31.520000,74.350000');
      final ios = LiveLocationMap.mapsLink(31.52, 74.35, platform: TargetPlatform.iOS, web: false);
      expect(ios.host, 'maps.apple.com');
      expect(ios.queryParameters['q'], '31.520000,74.350000');
      final web = LiveLocationMap.mapsLink(31.52, 74.35, platform: TargetPlatform.android, web: true);
      expect(web.host, 'www.openstreetmap.org');
      expect(web.queryParameters['mlat'], '31.520000');
    });
  });
}


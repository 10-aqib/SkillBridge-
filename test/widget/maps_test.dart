import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/map/maps_api.dart';
import 'package:skill_bridge/core/map/maps_config.dart';
import 'package:skill_bridge/core/map/sb_google_map.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/map_unavailable.dart';
import 'package:skill_bridge/core/map/maps_links.dart';
import 'package:skill_bridge/core/services/location_service.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/widgets/location_picker_screen.dart';

import '../helpers/fake_map.dart';
import '../helpers/fake_maps_api.dart';
import '../helpers/test_app.dart';

const _lahore = GeoCoord(31.5204, 74.3587);

Future<void> settle(WidgetTester tester, [int steps = 12]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ButtonStyleButton _button(WidgetTester tester, String label) => tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>()).first,
    );

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  group('LocationPickerScreen (GPS)', () {
    Future<LocationResult?> Function() openPicker(WidgetTester tester, {required PickerLocator locator, GeoCoord? initial}) {
      LocationResult? result;
      return () async {
        await tester.pumpWidget(testApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await Navigator.of(context).push<LocationResult>(
                MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: locator, initialLocation: initial)),
              ),
              child: const Text('open'),
            ),
          ),
        ));
        await tester.tap(find.text('open'));
        await settle(tester);
        return result;
      };
    }

    testWidgets('locates the device and confirms that spot with its GPS accuracy', (tester) async {
      LocationResult? result;
      await tester.pumpWidget(testApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push<LocationResult>(
              MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: () async => (point: _lahore, accuracy: 8.0))),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester);

      expect(find.text('31.52040, 74.35870'), findsOneWidget);
      expect(find.text(l.liveAccuracy(8)), findsOneWidget);
      expect(find.byType(SbMapUnavailable), findsOneWidget, reason: 'no map provider in this build');
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(_lahore.latitude, 1e-9));
      expect(result!.longitude, closeTo(_lahore.longitude, 1e-9));
      expect(result!.formattedAddress, '31.52040, 74.35870');
      expect(result!.city, '');
      expect(result!.accuracy, LocationAccuracyLevel.high);
    });

    testWidgets('an existing place is kept without asking for GPS, with unknown accuracy', (tester) async {
      var asked = 0;
      final open = openPicker(tester, initial: _lahore, locator: () async {
        asked++;
        return (point: _lahore, accuracy: 5.0);
      });
      await open();
      expect(asked, 0);
      expect(_button(tester, l.pickerConfirm).onPressed, isNotNull);
    });

    for (final (name, error, message, action) in [
      ('denied', LocationServiceException('x', isPermissionDenied: true), 'pickerLocationDenied', 'tryAgain'),
      ('blocked', LocationServiceException('x', isSettingsRequired: true), 'pickerLocationBlocked', 'liveOpenSettings'),
      ('GPS off', LocationServiceException('x', isServiceDisabled: true), 'pickerLocationServiceOff', 'liveOpenSettings'),
      ('timeout', LocationServiceException('x'), 'pickerLocationFailed', 'tryAgain'),
    ]) {
      testWidgets('location $name: explained, and nothing can be confirmed', (tester) async {
        await openPicker(tester, locator: () async => throw error)();
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
        expect(_button(tester, l.pickerConfirm).onPressed, isNull, reason: 'no place known');
      });
    }

    testWidgets('an invalid fix (0,0) is refused, not confirmed', (tester) async {
      await openPicker(tester, locator: () async => (point: const GeoCoord(0, 0), accuracy: 5.0))();
      expect(find.text(l.pickerLocationFailed), findsOneWidget);
      expect(_button(tester, l.pickerConfirm).onPressed, isNull);
    });

    testWidgets('retrying after a failure finds the device', (tester) async {
      var calls = 0;
      await openPicker(tester, locator: () async {
        if (calls++ == 0) throw LocationServiceException('x', isPermissionDenied: true);
        return (point: _lahore, accuracy: 12.0);
      })();
      await tester.tap(find.text(l.tryAgain));
      await settle(tester);
      expect(find.text(l.pickerLocationDenied), findsNothing);
      expect(find.text('31.52040, 74.35870'), findsOneWidget);
      expect(_button(tester, l.pickerConfirm).onPressed, isNotNull);
    });
  });

  group('SbGoogleMap', () {
    Future<FakeMaps> pumpMap(WidgetTester tester, Widget map,
        {bool available = true, bool online = true, Brightness brightness = Brightness.light, bool allowed = false}) async {
      final maps = FakeMaps();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(testApp(
        brightness: brightness,
        overrides: [
          if (available) ...maps.overrides else mapsAvailableProvider.overrideWithValue(false),
          connectivityStatusProvider.overrideWith((ref) => Stream.value(online)),
          mapMyLocationAllowedProvider.overrideWith((ref) async => allowed),
        ],
        home: Scaffold(body: map),
      ));
      await settle(tester, 3);
      return maps;
    }

    testWidgets('without a Maps key: "Map unavailable", never a grey map', (tester) async {
      final maps = await pumpMap(tester, const SbGoogleMap(initialCenter: _lahore), available: false);
      expect(find.byType(SbMapUnavailable), findsOneWidget);
      expect(maps.spec, isNull);
    });

    testWidgets('an invalid centre (0,0) is not drawn', (tester) async {
      final maps = await pumpMap(tester, const SbGoogleMap(initialCenter: GeoCoord(0, 0)));
      expect(find.byType(SbMapUnavailable), findsOneWidget);
      expect(maps.spec, isNull);
    });

    testWidgets('draws the given markers and circles; loading cover goes once the map is ready', (tester) async {
      var created = 0;
      final maps = await pumpMap(
        tester,
        SbGoogleMap(
          initialCenter: _lahore,
          onCreated: (_) => created++,
          markers: const [
            SbMarker(id: 'pin', position: _lahore, kind: SbMarkerKind.destination),
          ],
          circles: const [SbCircle(id: 'r', center: _lahore, radiusMetres: 500)],
        ),
      );
      expect(created, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(maps.marker('pin')!.kind, SbMarkerKind.destination);
      expect(maps.spec!.circles.single.radiusMetres, 500);
      expect(maps.spec!.initialCenter, _lahore);
    });

    testWidgets('offline shows a notice over the map', (tester) async {
      await pumpMap(tester, const SbGoogleMap(initialCenter: _lahore), online: false);
      expect(find.text(l.mapOffline), findsOneWidget);
      await pumpMap(tester, const SbGoogleMap(initialCenter: _lahore));
      expect(find.text(l.mapOffline), findsNothing);
    });

    testWidgets('recenter and zoom buttons only when asked for; recenter calls back', (tester) async {
      var recentred = 0;
      await pumpMap(tester, const SbGoogleMap(initialCenter: _lahore));
      expect(find.byTooltip(l.mapRecenter), findsNothing);
      final maps = await pumpMap(tester, SbGoogleMap(initialCenter: _lahore, onRecenter: () => recentred++, showZoomButtons: true));
      await tester.tap(find.byTooltip(l.mapRecenter));
      expect(recentred, 1);
      await tester.tap(find.byTooltip(l.mapZoomIn));
      await settle(tester, 2);
      expect(maps.controller.lastMove!.zoom, 16);
    });

    testWidgets('a preview has no controls even when given them', (tester) async {
      final maps = await pumpMap(tester, SbGoogleMap(initialCenter: _lahore, interactive: false, onRecenter: () {}, showZoomButtons: true));
      expect(find.byTooltip(l.mapRecenter), findsNothing);
      expect(maps.spec!.interactive, isFalse);
    });

    testWidgets('the blue dot only when location is already allowed; dark theme gets the dark style', (tester) async {
      var maps = await pumpMap(tester, const SbGoogleMap(initialCenter: _lahore, showMyLocation: true));
      expect(maps.spec!.showMyLocation, isFalse);
      expect(maps.spec!.dark, isFalse);
      maps = await pumpMap(tester, const SbGoogleMap(initialCenter: _lahore, showMyLocation: true), allowed: true, brightness: Brightness.dark);
      expect(maps.spec!.showMyLocation, isTrue);
      expect(maps.spec!.dark, isTrue);
    });
  });

  group('LocationPickerScreen (Google map)', () {
    Future<(FakeMaps, LocationResult? Function())> openWithMap(WidgetTester tester,
        {required PickerLocator locator, GeoCoord? initial, FakeMapsApi? api}) async {
      final maps = FakeMaps();
      LocationResult? result;
      await tester.pumpWidget(testApp(
        overrides: [
          ...maps.overrides,
          mapMyLocationAllowedProvider.overrideWith((ref) async => false),
          mapsApiProvider.overrideWithValue(api ?? FakeMapsApi(available: false)),
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push<LocationResult>(
              MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: locator, initialLocation: initial)),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester);
      return (maps, () => result);
    }

    testWidgets('GPS fix moves the map there; confirm returns the map centre with GPS accuracy', (tester) async {
      final (maps, result) = await openWithMap(tester, locator: () async => (point: _lahore, accuracy: 8.0));
      expect(maps.controller.lastMove, (point: _lahore, zoom: 17.0));
      maps.moveCamera(_lahore, 17);
      await settle(tester, 2);
      expect(find.text(l.liveAccuracy(8)), findsOneWidget);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result()!.latitude, closeTo(_lahore.latitude, 1e-9));
      expect(result()!.accuracy, LocationAccuracyLevel.high);
    });

    testWidgets('moving the map picks a new spot (accuracy unknown); zoomed out too far cannot confirm', (tester) async {
      final (maps, result) = await openWithMap(tester, locator: () async => (point: _lahore, accuracy: 8.0));
      const elsewhere = GeoCoord(31.5497, 74.3436);
      maps.moveCamera(elsewhere, 10);
      await settle(tester, 2);
      expect(find.text(l.pickerZoomInHint), findsOneWidget);
      expect(_button(tester, l.pickerConfirm).onPressed, isNull);
      maps.moveCamera(elsewhere, 15);
      await settle(tester, 2);
      expect(find.text(l.pickerMoveHint), findsOneWidget);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result()!.latitude, closeTo(elsewhere.latitude, 1e-9));
      expect(result()!.formattedAddress, '31.54970, 74.34360');
      expect(result()!.accuracy, LocationAccuracyLevel.unknown);
    });

    testWidgets('location denied: explained; the country view cannot be confirmed until zoomed in', (tester) async {
      final (maps, _) = await openWithMap(tester, locator: () async => throw LocationServiceException('x', isPermissionDenied: true));
      expect(find.text(l.pickerLocationDenied), findsOneWidget);
      expect(maps.spec!.initialCenter, LocationPickerScreen.pakistanOverview);
      expect(maps.spec!.initialZoom, 5);
      expect(_button(tester, l.pickerConfirm).onPressed, isNull);
      maps.moveCamera(_lahore, 16);
      await settle(tester, 2);
      expect(_button(tester, l.pickerConfirm).onPressed, isNotNull);
    });

    testWidgets('an existing place opens there without GPS', (tester) async {
      var asked = 0;
      final (maps, _) = await openWithMap(tester, initial: _lahore, locator: () async {
        asked++;
        return (point: _lahore, accuracy: 5.0);
      });
      expect(asked, 0);
      expect(maps.spec!.initialCenter, _lahore);
      expect(maps.spec!.initialZoom, 16);
      expect(_button(tester, l.pickerConfirm).onPressed, isNotNull);
    });
  });

  group('LocationPickerScreen (Google search and addresses)', () {
    Future<(FakeMaps, LocationResult? Function())> open(WidgetTester tester, FakeMapsApi api, {PickerLocator? locator}) async {
      final maps = FakeMaps();
      LocationResult? result;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(testApp(
        overrides: [...maps.overrides, mapMyLocationAllowedProvider.overrideWith((ref) async => false), mapsApiProvider.overrideWithValue(api)],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push<LocationResult>(
              MaterialPageRoute(builder: (_) => LocationPickerScreen(locator: locator ?? () async => (point: _lahore, accuracy: 8.0))),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester);
      return (maps, () => result);
    }

    testWidgets('the GPS spot gets its Google address; confirming returns that address and city', (tester) async {
      final api = FakeMapsApi(address: const MapPlace(point: _lahore, label: 'Mall Road, Lahore, Pakistan', city: 'Lahore'));
      final (maps, result) = await open(tester, api);
      expect(api.reverses, [_lahore]);
      expect(find.text('Mall Road, Lahore, Pakistan'), findsOneWidget);
      maps.moveCamera(_lahore, 17);
      await settle(tester, 10);
      expect(api.reverses, hasLength(1), reason: 'same spot is not looked up twice');
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result()!.formattedAddress, 'Mall Road, Lahore, Pakistan');
      expect(result()!.city, 'Lahore');
    });

    testWidgets('after moving the map, the old address is not reused: the new spot is looked up', (tester) async {
      final api = FakeMapsApi(address: const MapPlace(point: _lahore, label: 'Mall Road, Lahore, Pakistan', city: 'Lahore'));
      final (maps, result) = await open(tester, api);
      const elsewhere = GeoCoord(31.5497, 74.3436);
      api.address = const MapPlace(point: elsewhere, label: 'Davis Road, Lahore, Pakistan', city: 'Lahore');
      maps.moveCamera(elsewhere, 16);
      await settle(tester, 10); // past the 700 ms settle
      expect(api.reverses.last, elsewhere);
      expect(find.text('Davis Road, Lahore, Pakistan'), findsOneWidget);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result()!.formattedAddress, 'Davis Road, Lahore, Pakistan');
    });

    testWidgets('search runs on submit only; choosing a result moves the map and confirms that place', (tester) async {
      const liberty = GeoCoord(31.5106, 74.3448);
      final api = FakeMapsApi(places: const [MapPlace(point: liberty, name: 'Liberty Market', label: 'Liberty Market, Gulberg III, Lahore', city: 'Lahore')]);
      final (maps, result) = await open(tester, api);
      await tester.enterText(find.byType(TextField), 'li');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester, 3);
      expect(find.text(l.pickerSearchTooShort), findsOneWidget);
      expect(api.searches, isEmpty);

      await tester.enterText(find.byType(TextField), 'liberty market');
      await settle(tester, 3);
      expect(api.searches, isEmpty, reason: 'no search while typing');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester, 3);
      expect(api.searches, ['liberty market']);
      expect(find.text(l.pickerSearchAttributionGoogle), findsOneWidget);
      await tester.tap(find.text('Liberty Market'));
      await settle(tester, 3);
      expect(maps.controller.lastMove, (point: liberty, zoom: 17.0));
      maps.moveCamera(liberty, 17);
      await settle(tester, 10);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result()!.latitude, closeTo(liberty.latitude, 1e-9));
      expect(result()!.formattedAddress, 'Liberty Market, Gulberg III, Lahore');
      expect(result()!.city, 'Lahore');
    });

    testWidgets('search problems are explained: nothing found, service down', (tester) async {
      final api = FakeMapsApi();
      await open(tester, api);
      await tester.enterText(find.byType(TextField), 'zzzz nothing');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester, 3);
      expect(find.text(l.pickerSearchNoResults), findsOneWidget);
      api.searchFailure = MapsApiFailure.offline;
      await tester.tap(find.byTooltip(l.search));
      await settle(tester, 3);
      expect(find.text(l.pickerSearchFailed), findsOneWidget);
    });

    testWidgets('without the maps server there is no search box and coordinates stand in for the address', (tester) async {
      final api = FakeMapsApi(available: false);
      final (_, result) = await open(tester, api);
      expect(find.byType(TextField), findsNothing);
      expect(api.reverses, isEmpty);
      await tester.tap(find.text(l.pickerConfirm));
      await settle(tester, 5);
      expect(result()!.formattedAddress, '31.52040, 74.35870');
    });
  });

  group('GoogleMapsLinks', () {
    test('place link is the documented Maps URL with six-decimal coordinates', () {
      expect(GoogleMapsLinks.place(_lahore).toString(), 'https://www.google.com/maps/search/?api=1&query=31.520400%2C74.358700');
    });

    test('directions go to the destination by car, from the device unless an origin is given', () {
      final d = GoogleMapsLinks.directions(_lahore);
      expect(d.host, 'www.google.com');
      expect(d.path, '/maps/dir/');
      expect(d.queryParameters, {'api': '1', 'destination': '31.520400,74.358700', 'travelmode': 'driving'});
      final withOrigin = GoogleMapsLinks.directions(_lahore, origin: const GeoCoord(31.5, 74.3), mode: 'walking');
      expect(withOrigin.queryParameters['origin'], '31.500000,74.300000');
      expect(withOrigin.queryParameters['travelmode'], 'walking');
    });
  });

  group('GeoCoord', () {
    test('validity rejects out-of-range, non-finite and (0,0)', () {
      expect(_lahore.isValid, isTrue);
      expect(const GeoCoord(0, 0).isValid, isFalse);
      expect(const GeoCoord(91, 10).isValid, isFalse);
      expect(const GeoCoord(10, 181).isValid, isFalse);
      expect(const GeoCoord(double.nan, 10).isValid, isFalse);
    });

    test('distance matches a known value (Lahore to Islamabad, about 270 km)', () {
      final d = distanceMetres(_lahore, const GeoCoord(33.6844, 73.0479));
      expect(d, closeTo(270000, 6000));
      expect(distanceMetres(_lahore, _lahore), 0);
    });
  });
}

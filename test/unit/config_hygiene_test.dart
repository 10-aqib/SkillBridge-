import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/services/app_check_setup.dart';
import 'package:skill_bridge/core/services/crashlytics_service.dart';

void main() {
  group('.env is not a bundled asset', () {
    test('pubspec.yaml does not list .env under flutter assets', () {
      final pubspec = File('pubspec.yaml').readAsLinesSync();
      final assetLines = pubspec
          .map((l) => l.trim())
          .where((l) => l.startsWith('- ') && !l.startsWith('#'));
      expect(assetLines.any((l) => l == '- .env' || l.endsWith('/.env')), isFalse);
    });

    test('no API key is written into tracked platform config', () {
      // Keys come from the git-ignored .env at build time, never from files
      // in the repo. Google API keys start with "AIza".
      for (final x in [
        'android/app/build.gradle.kts',
        'android/app/src/main/AndroidManifest.xml',
        'ios/Runner/Info.plist',
        'ios/Runner/AppDelegate.swift',
        'ios/Flutter/Debug.xcconfig',
        'ios/Flutter/Release.xcconfig',
        'web/index.html',
      ]) {
        final f = File(x);
        if (!f.existsSync()) continue;
        expect(f.readAsStringSync(), isNot(contains('AIza')), reason: x);
      }
    });
  });

  group('Google Maps key wiring (Phase G2)', () {
    test('Android reads the key only from build dart-defines, through a manifest placeholder', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('com.google.android.geo.API_KEY'));
      expect(manifest, contains(r'${mapsApiKey}'));
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('dart-defines'));
      expect(gradle, isNot(contains('.env')), reason: 'a build without --dart-define-from-file must not pick up the key');
    });

    test('iOS reads the key from the git-ignored xcconfig', () {
      expect(File('ios/Runner/Info.plist').readAsStringSync(), contains(r'$(GOOGLE_MAPS_API_KEY)'));
      expect(File('.gitignore').readAsStringSync(), contains('ios/Flutter/GoogleMaps.local.xcconfig'));
    });

    test('web index.html loads no Maps script with a key (the app loads it at start-up)', () {
      expect(File('web/index.html').readAsStringSync(), isNot(contains('maps.googleapis.com')));
    });
  });

  group('old OpenStreetMap stack is gone (Phase G1)', () {
    test('no OSM, OSRM, Nominatim, TTS or wakelock packages', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final pkg in ['flutter_map', 'latlong2', 'flutter_tts', 'wakelock_plus']) {
        expect(pubspec, isNot(contains('$pkg:')), reason: pkg);
      }
    });

    test('no app code talks to the old providers', () {
      final hits = <String>[];
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        if (f.path.contains('generated')) continue;
        final text = f.readAsStringSync().toLowerCase();
        for (final word in ['openstreetmap', 'osrm', 'nominatim', 'package:flutter_map', 'package:latlong2']) {
          if (text.contains(word)) hits.add('${f.path}: $word');
        }
      }
      expect(hits, isEmpty);
    });

    test('.env.example has no old map settings', () {
      final env = File('.env.example').readAsStringSync();
      for (final v in ['MAP_TILE_', 'ROUTING_', 'GEOCODING_']) {
        expect(env, isNot(contains(v)), reason: v);
      }
    });
  });

  group('App Check mode', () {
    test('debug builds use debug providers on every platform', () {
      for (final web in [true, false]) {
        expect(AppCheckSetup.modeFor(isWeb: web, isDebug: true, siteKey: ''), AppCheckMode.debug);
      }
    });

    test('web release without a site key skips App Check instead of using a placeholder', () {
      expect(
        AppCheckSetup.modeFor(isWeb: true, isDebug: false, siteKey: ''),
        AppCheckMode.skippedNoWebSiteKey,
      );
      expect(
        AppCheckSetup.modeFor(isWeb: true, isDebug: false, siteKey: '  '),
        AppCheckMode.skippedNoWebSiteKey,
      );
    });

    test('web release with a site key and mobile release use production providers', () {
      expect(
        AppCheckSetup.modeFor(isWeb: true, isDebug: false, siteKey: '6Lc-example'),
        AppCheckMode.production,
      );
      expect(
        AppCheckSetup.modeFor(isWeb: false, isDebug: false, siteKey: ''),
        AppCheckMode.production,
      );
    });

    test('the old placeholder key is gone from main.dart', () {
      expect(File('lib/main.dart').readAsStringSync(), isNot(contains('recaptcha-v3-site-key')));
    });
  });

  group('Crashlytics on unsupported platforms', () {
    test('construction does not touch FirebaseCrashlytics (no Firebase in tests)', () {
      // Before the fix this threw: FirebaseCrashlytics.instance was read eagerly.
      expect(() => CrashlyticsService(isSupported: false), returnsNormally);
    });

    test('every method is a silent no-op when unsupported', () async {
      final service = CrashlyticsService(isSupported: false);
      await service.init();
      await service.setUserId('uid');
      await service.setUserRole('client');
      service.log('message');
      await service.recordError(StateError('x'), StackTrace.current);
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/services/app_check_setup.dart';
import 'package:skill_bridge/core/services/crashlytics_service.dart';
import 'package:skill_bridge/core/services/google_maps_service.dart';

void main() {
  group('.env is not a bundled asset', () {
    test('pubspec.yaml does not list .env under flutter assets', () {
      final pubspec = File('pubspec.yaml').readAsLinesSync();
      final assetLines = pubspec
          .map((l) => l.trim())
          .where((l) => l.startsWith('- ') && !l.startsWith('#'));
      expect(assetLines.any((l) => l == '- .env' || l.endsWith('/.env')), isFalse);
    });

    test('Maps key is absent unless provided at build time', () {
      // Tests run without --dart-define-from-file, so the key is empty and
      // callers get a clear error instead of silently reading a bundled file.
      expect(() => GoogleMapsService.apiKey, throwsA(isA<GoogleMapsServiceException>()));
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

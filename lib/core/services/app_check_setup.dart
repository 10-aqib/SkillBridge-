import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// How App Check should start for a given build.
enum AppCheckMode {
  /// Debug builds: Firebase debug providers. Register the debug token printed
  /// in the logs (or passed as APP_CHECK_DEBUG_TOKEN) in the Firebase console.
  debug,

  /// Release/profile builds: Play Integrity (Android), DeviceCheck (Apple),
  /// reCAPTCHA v3 (web).
  production,

  /// Web release build without a reCAPTCHA site key: App Check is not started,
  /// instead of starting with an invalid key (which only produced 400 errors).
  skippedNoWebSiteKey,
}

/// Firebase App Check start-up.
///
/// Build-time values (pass with `--dart-define` or `--dart-define-from-file`):
/// * `RECAPTCHA_V3_SITE_KEY` — public reCAPTCHA v3 **site** key registered for
///   the web app under Firebase console → App Check. Not a secret.
/// * `APP_CHECK_DEBUG_TOKEN` — optional debug token (debug builds only). Treat
///   as a secret: anyone holding it can pass App Check while it's registered.
///
/// This only chooses providers. Whether Firebase *rejects* requests without a
/// valid token is the console's "enforcement" setting, which this code does not
/// change.
abstract final class AppCheckSetup {
  static const String webSiteKey = String.fromEnvironment('RECAPTCHA_V3_SITE_KEY');
  static const String debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

  @visibleForTesting
  static AppCheckMode modeFor({
    required bool isWeb,
    required bool isDebug,
    required String siteKey,
  }) {
    if (isDebug) return AppCheckMode.debug;
    if (isWeb && siteKey.trim().isEmpty) return AppCheckMode.skippedNoWebSiteKey;
    return AppCheckMode.production;
  }

  static Future<AppCheckMode> activate({FirebaseAppCheck? appCheck}) async {
    final mode = modeFor(isWeb: kIsWeb, isDebug: kDebugMode, siteKey: webSiteKey);
    final token = debugToken.isEmpty ? null : debugToken;
    final instance = appCheck ?? FirebaseAppCheck.instance;

    switch (mode) {
      case AppCheckMode.skippedNoWebSiteKey:
        Logger.w(
          'App Check not started on web: no RECAPTCHA_V3_SITE_KEY was provided '
          'at build time. See design/PHASE2A1_CONFIG_HYGIENE_REPORT.md.',
        );
      case AppCheckMode.debug:
        await instance.activate(
          providerAndroid: AndroidDebugProvider(debugToken: token),
          providerApple: AppleDebugProvider(debugToken: token),
          providerWeb: WebDebugProvider(debugToken: token),
        );
        Logger.i('Firebase App Check started with debug providers');
      case AppCheckMode.production:
        await instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
          providerApple: const AppleDeviceCheckProvider(),
          providerWeb: kIsWeb ? ReCaptchaV3Provider(webSiteKey) : null,
        );
        Logger.i('Firebase App Check started');
    }
    return mode;
  }
}

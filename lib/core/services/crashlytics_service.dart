import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Crashlytics wrapper. Firebase Crashlytics has no web implementation, so on
/// web every method is a silent no-op. Previously the constructor touched
/// `FirebaseCrashlytics.instance` eagerly, which threw an uncaught error at web
/// start-up and on every sign-in (via `crashlyticsServiceProvider`).
class CrashlyticsService {
  final FirebaseCrashlytics? _override;
  final bool _supported;

  CrashlyticsService({FirebaseCrashlytics? crashlytics, bool? isSupported})
      : _override = crashlytics,
        _supported = isSupported ?? (crashlytics != null || isSupportedPlatform);

  /// Android and iOS/macOS only (not web, Windows or Linux).
  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  // Resolved only when used on a supported platform.
  FirebaseCrashlytics get _crashlytics => _override ?? FirebaseCrashlytics.instance;

  Future<void> init() async {
    if (!_supported) {
      Logger.i('Crashlytics not available on this platform; skipped');
      return;
    }
    try {
      if (kDebugMode) {
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
        Logger.i('Crashlytics disabled in debug mode');
      } else {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = _crashlytics.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics.recordError(error, stack, fatal: true);
          return true;
        };
        Logger.i('Crashlytics initialized for non-debug builds');
      }
    } catch (e, st) {
      Logger.e('Failed to initialize CrashlyticsService', e, st);
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!_supported) return;
    try {
      await _crashlytics.setUserIdentifier(userId ?? '');
    } catch (e, st) {
      Logger.e('Crashlytics setUserId error', e, st);
    }
  }

  Future<void> setUserRole(String role) async {
    if (!_supported) return;
    try {
      await _crashlytics.setCustomKey('user_role', role);
    } catch (e, st) {
      Logger.e('Crashlytics setUserRole error', e, st);
    }
  }

  void log(String message) {
    if (!_supported) return;
    try {
      _crashlytics.log(message);
    } catch (e, st) {
      Logger.e('Crashlytics log error', e, st);
    }
  }

  Future<void> recordError(dynamic error, StackTrace? stack, {String? reason, bool fatal = false}) async {
    if (!_supported) return;
    try {
      await _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);
    } catch (e, st) {
      Logger.e('Crashlytics recordError error', e, st);
    }
  }
}

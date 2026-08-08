import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_bridge/core/utils/logger.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> init() async {
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
    try {
      await _crashlytics.setUserIdentifier(userId ?? '');
    } catch (e, st) {
      Logger.e('Crashlytics setUserId error', e, st);
    }
  }

  Future<void> setUserRole(String role) async {
    try {
      await _crashlytics.setCustomKey('user_role', role);
    } catch (e, st) {
      Logger.e('Crashlytics setUserRole error', e, st);
    }
  }

  void log(String message) {
    try {
      _crashlytics.log(message);
    } catch (e, st) {
      Logger.e('Crashlytics log error', e, st);
    }
  }

  Future<void> recordError(dynamic error, StackTrace? stack, {String? reason, bool fatal = false}) async {
    try {
      await _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);
    } catch (e, st) {
      Logger.e('Crashlytics recordError error', e, st);
    }
  }
}

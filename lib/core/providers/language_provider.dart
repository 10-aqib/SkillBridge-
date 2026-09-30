import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/services/offline_cache_service.dart';

/// Riverpod 3.x Notifier for application localization and RTL Urdu mode.
/// Allows 1-tap switching between English (LTR) and Urdu اردو (RTL) across all screens.
class LanguageNotifier extends Notifier<Locale> {
  static const String _cacheKey = 'app_language_code';

  @override
  Locale build() {
    // English only across the app
    OfflineCacheService.save(_cacheKey, 'en');
    return const Locale('en');
  }

  bool get isUrdu => false;

  Future<void> toggleLanguage() async {
    // No-op: app is English-only
    state = const Locale('en');
    await OfflineCacheService.save(_cacheKey, 'en');
  }

  Future<void> setLanguage(String code) async {
    // No-op: app is English-only
    state = const Locale('en');
    await OfflineCacheService.save(_cacheKey, 'en');
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(() {
  return LanguageNotifier();
});

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
    final cached = OfflineCacheService.read(_cacheKey);
    if (cached == 'ur') {
      return const Locale('ur', 'PK');
    }
    return const Locale('en', 'US');
  }

  bool get isUrdu => state.languageCode == 'ur';

  Future<void> toggleLanguage() async {
    HapticFeedback.lightImpact();
    if (state.languageCode == 'en') {
      state = const Locale('ur', 'PK');
      await OfflineCacheService.save(_cacheKey, 'ur');
    } else {
      state = const Locale('en', 'US');
      await OfflineCacheService.save(_cacheKey, 'en');
    }
  }

  Future<void> setLanguage(String code) async {
    HapticFeedback.lightImpact();
    if (code == 'ur') {
      state = const Locale('ur', 'PK');
      await OfflineCacheService.save(_cacheKey, 'ur');
    } else {
      state = const Locale('en', 'US');
      await OfflineCacheService.save(_cacheKey, 'en');
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(() {
  return LanguageNotifier();
});

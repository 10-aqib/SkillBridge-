import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/network/network_info.dart';
import 'package:skill_bridge/core/services/hive_service.dart';

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfoImpl(connectivity);
});

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    return 'en';
  }

  void setLocale(String locale) {
    state = locale;
  }

  void toggle() {
    state = state == 'en' ? 'ur' : 'en';
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(() {
  return LocaleNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    try {
      final hive = ref.watch(hiveServiceProvider);
      final val = hive.settingsBox.get(_key) as String?;
      if (val == 'dark') return ThemeMode.dark;
      if (val == 'light') return ThemeMode.light;
    } catch (_) {}
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final hive = ref.read(hiveServiceProvider);
      String val = 'system';
      if (mode == ThemeMode.dark) val = 'dark';
      if (mode == ThemeMode.light) val = 'light';
      await hive.settingsBox.put(_key, val);
    } catch (_) {}
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

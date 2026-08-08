import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String authBoxName = 'auth_cache';
  static const String settingsBoxName = 'app_settings_cache';
  static const String searchHistoryBoxName = 'search_history_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await openBoxes();
  }

  Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox(authBoxName),
      Hive.openBox(settingsBoxName),
      Hive.openBox(searchHistoryBoxName),
    ]);
  }

  // Generic box getters
  Box get authBox => Hive.box(authBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);
  Box get searchHistoryBox => Hive.box(searchHistoryBoxName);

  // Clear cache helpers
  Future<void> clearAuthCache() async {
    await authBox.clear();
  }

  Future<void> clearAll() async {
    await Future.wait([
      authBox.clear(),
      settingsBox.clear(),
      searchHistoryBox.clear(),
    ]);
  }
}

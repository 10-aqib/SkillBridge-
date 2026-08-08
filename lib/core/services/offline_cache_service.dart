import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Offline-first Hive cache service for SkillBridge Pakistani marketplace.
/// Caches recent worker profiles, job listings, and user settings locally for low-connectivity environments.
class OfflineCacheService {
  static const String _boxName = 'skillbridge_offline_cache';
  static bool _isInitialized = false;

  /// Initialize Hive box for local offline storage.
  static Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    _isInitialized = true;
  }

  /// Save string or JSON data to offline cache.
  static Future<void> save(String key, dynamic value) async {
    final box = Hive.box(_boxName);
    if (value is Map || value is List) {
      await box.put(key, jsonEncode(value));
    } else {
      await box.put(key, value);
    }
  }

  /// Read cached data by key.
  static dynamic read(String key) {
    if (!Hive.isBoxOpen(_boxName)) return null;
    final box = Hive.box(_boxName);
    return box.get(key);
  }

  /// Clear offline cache.
  static Future<void> clear() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box(_boxName);
    await box.clear();
  }
}

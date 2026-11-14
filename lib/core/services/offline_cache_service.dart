import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Offline-first Hive cache service for SkillBridge Pakistani marketplace.
/// Caches recent worker profiles, job listings, and user settings locally for low-connectivity environments.
class OfflineCacheService {
  static const String _boxName = 'skillbridge_offline_cache';
  static bool _isInitialized = false;

  /// Initialize Hive box for local offline storage.
  static Future<void> init() async {
    if (_isInitialized) return;
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
    _isInitialized = true;
  }

  /// Save string or JSON data to offline cache.
  static Future<void> save(String key, dynamic value) async {
    final box = Hive.box(_boxName);
    if (value is Map || value is List) {
      await box.put(key, jsonEncode(_encodeCacheValue(value)));
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

  static dynamic readDecoded(String key) {
    final value = read(key);
    if (value is! String) return value;
    try {
      return _decodeCacheValue(jsonDecode(value));
    } catch (_) {
      return null;
    }
  }

  /// Clear offline cache.
  static Future<void> clear() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box(_boxName);
    await box.clear();
  }
}

dynamic _encodeCacheValue(dynamic value) {
  if (value is Timestamp) {
    return {'__cacheType': 'timestamp', 'value': value.millisecondsSinceEpoch};
  }
  if (value is GeoPoint) {
    return {
      '__cacheType': 'geoPoint',
      'latitude': value.latitude,
      'longitude': value.longitude,
    };
  }
  if (value is DateTime) {
    return {'__cacheType': 'dateTime', 'value': value.toIso8601String()};
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), _encodeCacheValue(item)),
    );
  }
  if (value is Iterable) return value.map(_encodeCacheValue).toList();
  return value;
}

dynamic _decodeCacheValue(dynamic value) {
  if (value is List) return value.map(_decodeCacheValue).toList();
  if (value is! Map) return value;
  final map = Map<String, dynamic>.from(value);
  switch (map['__cacheType']) {
    case 'timestamp':
      return Timestamp.fromMillisecondsSinceEpoch(map['value'] as int);
    case 'geoPoint':
      return GeoPoint(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      );
    case 'dateTime':
      return DateTime.parse(map['value'] as String);
    default:
      return map.map((key, item) => MapEntry(key, _decodeCacheValue(item)));
  }
}

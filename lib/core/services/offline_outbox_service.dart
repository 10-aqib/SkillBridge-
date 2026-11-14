import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class OutboxItem {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String? idempotencyKey;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastError;

  OutboxItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.idempotencyKey,
    this.attemptCount = 0,
    this.nextAttemptAt,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': _encodeFirestoreValue(payload),
    'createdAt': createdAt.toIso8601String(),
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    'attemptCount': attemptCount,
    if (nextAttemptAt != null)
      'nextAttemptAt': nextAttemptAt!.toIso8601String(),
    if (lastError != null) 'lastError': lastError,
  };

  factory OutboxItem.fromJson(Map<String, dynamic> json) => OutboxItem(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: Map<String, dynamic>.from(
      _decodeFirestoreValue(json['payload']) as Map,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    idempotencyKey: json['idempotencyKey'] as String?,
    attemptCount: json['attemptCount'] as int? ?? 0,
    nextAttemptAt: json['nextAttemptAt'] is String
        ? DateTime.tryParse(json['nextAttemptAt'] as String)
        : null,
    lastError: json['lastError'] as String?,
  );
}

/// Persistent outbox for writes that cannot be committed while offline.
class OfflineOutboxService {
  static const String _boxName = 'skillbridge_offline_outbox';
  static const Uuid _uuid = Uuid();

  /// Opens the outbox after the app's HiveService has initialized Hive.
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  /// Stores an action. A repeated idempotency key returns the existing item.
  static Future<String> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    if (!Hive.isBoxOpen(_boxName)) {
      throw StateError('Offline outbox has not been initialized.');
    }
    final box = Hive.box<String>(_boxName);
    if (idempotencyKey != null) {
      for (final item in getPendingItems()) {
        if (item.idempotencyKey == idempotencyKey) return item.id;
      }
    }

    final id = _uuid.v4();
    final item = OutboxItem(
      id: id,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
      idempotencyKey: idempotencyKey,
    );
    await box.put(id, jsonEncode(item.toJson()));
    return id;
  }

  static int pendingCount() {
    if (!Hive.isBoxOpen(_boxName)) return 0;
    return Hive.box<String>(_boxName).length;
  }

  static Stream<int> watchPendingCount() async* {
    if (!Hive.isBoxOpen(_boxName)) {
      yield 0;
      return;
    }
    final box = Hive.box<String>(_boxName);
    yield box.length;
    yield* box.watch().map((_) => box.length).distinct();
  }

  static List<OutboxItem> getPendingItems() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    final box = Hive.box<String>(_boxName);
    final items = <OutboxItem>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        items.add(OutboxItem.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Keep malformed records in place for inspection instead of discarding them.
      }
    }
    return items;
  }

  static Future<void> markAttemptFailed(OutboxItem item, Object error) async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final attempts = item.attemptCount + 1;
    final exponent = (attempts - 1).clamp(0, 9).toInt();
    final delaySeconds = (5 * (1 << exponent)).clamp(5, 1800).toInt();
    final updated = OutboxItem(
      id: item.id,
      type: item.type,
      payload: item.payload,
      createdAt: item.createdAt,
      idempotencyKey: item.idempotencyKey,
      attemptCount: attempts,
      nextAttemptAt: DateTime.now().add(Duration(seconds: delaySeconds)),
      lastError: error.toString(),
    );
    await Hive.box<String>(_boxName).put(item.id, jsonEncode(updated.toJson()));
  }

  static Future<void> clear() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    await Hive.box<String>(_boxName).clear();
  }

  static Future<void> remove(String id) async {
    if (!Hive.isBoxOpen(_boxName)) return;
    await Hive.box<String>(_boxName).delete(id);
  }
}

dynamic _encodeFirestoreValue(dynamic value) {
  if (value is Timestamp) {
    return {
      '__offlineType': 'timestamp',
      'value': value.toDate().toIso8601String(),
    };
  }
  if (value is GeoPoint) {
    return {
      '__offlineType': 'geoPoint',
      'latitude': value.latitude,
      'longitude': value.longitude,
    };
  }
  if (value is FieldValue) {
    return {'__offlineType': 'serverTimestamp'};
  }
  if (value is DateTime) {
    return {'__offlineType': 'dateTime', 'value': value.toIso8601String()};
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), _encodeFirestoreValue(item)),
    );
  }
  if (value is Iterable) {
    return value.map(_encodeFirestoreValue).toList();
  }
  return value;
}

dynamic _decodeFirestoreValue(dynamic value) {
  if (value is List) return value.map(_decodeFirestoreValue).toList();
  if (value is! Map) return value;

  final map = Map<String, dynamic>.from(value);
  switch (map['__offlineType']) {
    case 'timestamp':
    case 'dateTime':
      final date = DateTime.parse(map['value'] as String);
      return map['__offlineType'] == 'timestamp'
          ? Timestamp.fromDate(date)
          : date;
    case 'geoPoint':
      return GeoPoint(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      );
    case 'serverTimestamp':
      return FieldValue.serverTimestamp();
    default:
      return map.map((key, item) => MapEntry(key, _decodeFirestoreValue(item)));
  }
}

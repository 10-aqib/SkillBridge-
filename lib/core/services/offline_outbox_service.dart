import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Represents a queued offline mutation waiting to be synced to cloud servers.
class OutboxItem {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  OutboxItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OutboxItem.fromJson(Map<String, dynamic> json) => OutboxItem(
        id: json['id'] as String,
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Offline-first Hive Outbox queue for SkillBridge Pakistani marketplace.
/// Ensures reliable execution of chat messages, bookings, and reviews even during cellular data drops.
class OfflineOutboxService {
  static const String _boxName = 'skillbridge_offline_outbox';
  static bool _isInitialized = false;

  /// Initialize Hive outbox box.
  static Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
    _isInitialized = true;
  }

  /// Add a pending action to the offline queue.
  static Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<String>(_boxName);
    final item = OutboxItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await box.put(item.id, jsonEncode(item.toJson()));
  }

  /// Return the number of pending actions in the queue.
  static int pendingCount() {
    if (!Hive.isBoxOpen(_boxName)) return 0;
    final box = Hive.box<String>(_boxName);
    return box.length;
  }

  /// Get all queued pending items.
  static List<OutboxItem> getPendingItems() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    final box = Hive.box<String>(_boxName);
    final items = <OutboxItem>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          items.add(OutboxItem.fromJson(decoded));
        } catch (_) {
          // ignore malformed items
        }
      }
    }
    return items;
  }

  /// Clear the entire outbox queue after successful synchronization.
  static Future<void> clear() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<String>(_boxName);
    await box.clear();
  }

  /// Remove a specific item from the queue by ID.
  static Future<void> remove(String id) async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<String>(_boxName);
    await box.delete(id);
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/services/offline_outbox_service.dart';

/// Applies queued, idempotent Firestore writes and removes only acknowledged items.
class FirestoreOutboxSyncEngine {
  static final FirestoreOutboxSyncEngine _instance =
      FirestoreOutboxSyncEngine._internal();

  factory FirestoreOutboxSyncEngine() => _instance;

  FirestoreOutboxSyncEngine._internal({FirebaseFirestore? firestore})
    : _firestore = firestore;

  FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Timer? _retryTimer;
  final StreamController<int> _syncCountController =
      StreamController<int>.broadcast();
  Stream<int> get onSyncCompleted => _syncCountController.stream;

  Future<int> syncPendingItems() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    var syncedCount = 0;
    var hasFailures = false;

    try {
      final now = DateTime.now();
      final pending = OfflineOutboxService.getPendingItems().where(
        (item) =>
            item.nextAttemptAt == null || !item.nextAttemptAt!.isAfter(now),
      );

      for (final item in pending) {
        try {
          await _apply(item);
          await OfflineOutboxService.remove(item.id);
          syncedCount++;
        } catch (error) {
          hasFailures = hasFailures || _isRetryable(error);
          await OfflineOutboxService.markAttemptFailed(item, error);
        }
      }

      if (!_syncCountController.isClosed) {
        _syncCountController.add(syncedCount);
      }
      if (hasFailures) _scheduleRetry();
      return syncedCount;
    } finally {
      _isSyncing = false;
    }
  }

  bool _isRetryable(Object error) {
    if (error is! FirebaseException) return false;
    return const {
      'unavailable',
      'deadline-exceeded',
      'network-request-failed',
      'resource-exhausted',
      'aborted',
    }.contains(error.code);
  }

  Future<void> _apply(OutboxItem item) async {
    final payload = item.payload;
    switch (item.type) {
      case 'POST_JOB':
      case 'SEND_MESSAGE':
      case 'BOOK_WORKER':
      case 'FIRESTORE_SET':
        final path = _requiredPath(payload);
        final data = _requiredData(payload);
        await _db
            .doc(path)
            .set(data, SetOptions(merge: payload['merge'] as bool? ?? true));
        return;
      case 'FIRESTORE_UPDATE':
        await _db.doc(_requiredPath(payload)).update(_requiredData(payload));
        return;
      case 'FIRESTORE_BATCH':
        await _applyBatch(payload);
        return;
      default:
        throw FormatException('Unsupported offline action: ${item.type}');
    }
  }

  Future<void> _applyBatch(Map<String, dynamic> payload) async {
    final writes = payload['writes'];
    if (writes is! List || writes.isEmpty) {
      throw const FormatException(
        'A Firestore batch needs at least one write.',
      );
    }

    final batch = _db.batch();
    for (final rawWrite in writes) {
      if (rawWrite is! Map) {
        throw const FormatException('A Firestore batch write is malformed.');
      }
      final write = Map<String, dynamic>.from(rawWrite);
      final reference = _db.doc(_requiredPath(write));
      switch (write['operation']) {
        case 'set':
          batch.set(
            reference,
            _requiredData(write),
            SetOptions(merge: write['merge'] as bool? ?? true),
          );
          break;
        case 'update':
          batch.update(reference, _requiredData(write));
          break;
        case 'delete':
          batch.delete(reference);
          break;
        default:
          throw FormatException(
            'Unsupported batch operation: ${write['operation']}',
          );
      }
    }
    await batch.commit();
  }

  String _requiredPath(Map<String, dynamic> payload) {
    final path = payload['documentPath'];
    if (path is! String || path.isEmpty || path.split('/').length.isOdd) {
      throw const FormatException(
        'A valid Firestore documentPath is required.',
      );
    }
    return path;
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is! Map) {
      throw const FormatException('A Firestore data map is required.');
    }
    final decoded = _decodeOfflineValue(data);
    return Map<String, dynamic>.from(decoded as Map);
  }

  dynamic _decodeOfflineValue(dynamic value) {
    if (value is List) return value.map(_decodeOfflineValue).toList();
    if (value is! Map) return value;
    final map = Map<String, dynamic>.from(value);
    if (map['__offlineType'] == 'increment') {
      return FieldValue.increment((map['value'] as num).toDouble());
    }
    return map.map((key, item) => MapEntry(key, _decodeOfflineValue(item)));
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final nextAttempt = OfflineOutboxService.getPendingItems()
        .map((item) => item.nextAttemptAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (earliest, value) =>
              earliest == null || value.isBefore(earliest) ? value : earliest,
        );
    final delay = nextAttempt == null
        ? const Duration(seconds: 30)
        : nextAttempt.difference(DateTime.now());
    _retryTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(syncPendingItems()),
    );
  }

  void dispose() {
    _retryTimer?.cancel();
    _syncCountController.close();
  }
}

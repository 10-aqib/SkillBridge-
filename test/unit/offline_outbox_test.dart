import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skill_bridge/core/services/offline_outbox_service.dart';

void main() {
  group('OfflineOutboxService', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('skillbridge_outbox_test');
      Hive.init(tempDir.path);
      await Hive.openBox<String>('skillbridge_offline_outbox');
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('OutboxItem serializes and deserializes correctly', () {
      final item = OutboxItem(
        id: 'outbox_123',
        type: 'SEND_MESSAGE',
        payload: {'text': 'Salam, kab ayenge?', 'contractId': 'contract_1'},
        createdAt: DateTime.parse('2026-08-04T12:00:00.000Z'),
      );

      final json = item.toJson();
      expect(json['id'], equals('outbox_123'));
      expect(json['type'], equals('SEND_MESSAGE'));

      final restored = OutboxItem.fromJson(json);
      expect(restored.id, equals('outbox_123'));
      expect(restored.payload['text'], equals('Salam, kab ayenge?'));
    });

    test('enqueue adds item and pendingCount increments', () async {
      await OfflineOutboxService.clear();
      expect(OfflineOutboxService.pendingCount(), equals(0));

      await OfflineOutboxService.enqueue(
        type: 'POST_JOB',
        payload: {'title': 'Bijli wala wiring repair', 'budget': 2000},
      );

      expect(OfflineOutboxService.pendingCount(), equals(1));

      final items = OfflineOutboxService.getPendingItems();
      expect(items.length, equals(1));
      expect(items.first.type, equals('POST_JOB'));
      expect(items.first.payload['title'], equals('Bijli wala wiring repair'));

      await OfflineOutboxService.clear();
      expect(OfflineOutboxService.pendingCount(), equals(0));
    });
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skill_bridge/core/services/app_notification_service.dart';
import 'package:skill_bridge/core/services/firestore_outbox_sync_engine.dart';
import 'package:skill_bridge/core/services/offline_outbox_service.dart';

void main() {
  group('FirestoreOutboxSyncEngine', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'skillbridge_sync_test_dir',
      );
      Hive.init(tempDir.path);
      await Hive.openBox<String>('skillbridge_offline_outbox');
    });

    tearDownAll(() async {
      await OfflineOutboxService.clear();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'syncPendingItems keeps actions until Firestore acknowledges them',
      () async {
        await OfflineOutboxService.clear();
        await OfflineOutboxService.enqueue(
          type: 'POST_JOB',
          payload: {'title': 'Fix AC', 'budget': 3500},
        );
        await OfflineOutboxService.enqueue(
          type: 'SEND_MESSAGE',
          payload: {'text': 'Salam Ustad'},
        );

        expect(OfflineOutboxService.pendingCount(), equals(2));

        final syncEngine = FirestoreOutboxSyncEngine();
        final count = await syncEngine.syncPendingItems();

        // There is no initialized Firebase app in this test, so writes cannot be
        // acknowledged. A failed sync must leave both queued actions intact.
        expect(count, equals(0));
        expect(OfflineOutboxService.pendingCount(), equals(2));
      },
    );
  });

  group('AppNotificationService', () {
    test('escrowConfirmed formats bilingual English and Urdu title', () {
      final notif = AppNotificationService.escrowConfirmed(3500);
      final title = notif.formatBilingualTitle();
      expect(title, contains('Rs. 3500 Raast Escrow Confirmed'));
      expect(title, contains('راست ایسکرو تصدیق شدہ'));
    });

    test('workerArrived formats bilingual arrival title and body', () {
      final notif = AppNotificationService.workerArrived('Ustad Ali');
      expect(notif.titleEn, contains('Ustad Ali Arrived'));
      expect(notif.titleUr, contains('استاد آپ کے پتے پر پہنچ گئے'));
    });

    test('proposalReceived formats bilingual bid amount and worker', () {
      final notif = AppNotificationService.proposalReceived(
        'Kamran Electrician',
        4500,
      );
      final title = notif.formatBilingualTitle();
      expect(title, contains('Rs. 4500'));
      expect(title, contains('Kamran Electrician'));
      expect(title, contains('نئی پیشکش'));
    });
  });
}

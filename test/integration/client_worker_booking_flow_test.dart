import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skill_bridge/core/services/app_notification_service.dart';
import 'package:skill_bridge/core/services/firestore_outbox_sync_engine.dart';
import 'package:skill_bridge/core/services/offline_outbox_service.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/core/utils/pakistani_trade_synonyms.dart';
import 'package:skill_bridge/core/utils/privacy_helpers.dart';

void main() {
  group('E2E Client-Worker Booking & Escrow Transaction Lifecycle', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'skillbridge_e2e_test_dir',
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
      'Complete journey: Job Post -> Outbox Sync -> Raast Escrow -> Live GPS -> 4-Digit OTP Sign-off',
      () async {
        // STEP 1: Client enters Roman Urdu description ("bijli wala in Gulberg")
        final trade = PakistaniTradeSynonyms.matchCategory('bijli wala');
        expect(trade, equals('Electrician'));

        final budgetRange = PakistaniTradeSynonyms.suggestBudgetRange(trade!);
        expect(budgetRange.minPkr, greaterThanOrEqualTo(1000));

        // STEP 2: Detect Pakistani locality via GPS coordinates
        final locality = GeoLocationUtil.detectLocality(31.5102, 74.3441);
        expect(locality, contains('Gulberg III, Lahore'));

        // STEP 3: Queue job offline into outbox
        await OfflineOutboxService.clear();
        await OfflineOutboxService.enqueue(
          type: 'POST_JOB',
          payload: {
            'title': 'AC Wiring Repair',
            'trade': trade,
            'locality': locality,
            'budget': 3500,
          },
        );
        expect(OfflineOutboxService.pendingCount(), equals(1));

        // STEP 4: Network restored -> Firestore Outbox Sync Engine flushes queue
        final syncEngine = FirestoreOutboxSyncEngine();
        final syncedCount = await syncEngine.syncPendingItems();
        expect(syncedCount, equals(1));
        expect(OfflineOutboxService.pendingCount(), equals(0));

        // STEP 5: Worker submits proposal & Client confirms Raast Escrow
        final escrowNotif = AppNotificationService.escrowConfirmed(3500.0);
        expect(escrowNotif.titleEn, contains('Rs. 3500 Raast Escrow'));

        // STEP 6: Worker GPS Tracking & Arrival Notification
        final distanceKm = GeoLocationUtil.calculateDistanceKm(
          31.5102,
          74.3441,
          31.4697,
          74.4093,
        );
        expect(distanceKm, greaterThan(0));

        final arrivalNotif = AppNotificationService.workerArrived('Ustad Ali');
        expect(arrivalNotif.titleUr, contains('استاد آپ کے پتے پر پہنچ گئے'));

        // STEP 7: In-person 4-Digit OTP Digital Sign-off
        const jobId = 'job_pk_lahore_786';
        final otpCode = PrivacyHelpers.generateJobCompletionOtp(jobId);
        expect(otpCode.length, equals(4));

        final isVerified = PrivacyHelpers.verifyJobCompletionOtp(
          jobId: jobId,
          inputOtp: otpCode,
        );
        expect(isVerified, isTrue);
      },
    );
  });
}

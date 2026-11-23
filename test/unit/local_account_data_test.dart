// What this device keeps for an account is removed when that account signs
// out or another account signs in, never during a reload (PRIVACY_POLICY.md §21).
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skill_bridge/core/services/hive_service.dart';
import 'package:skill_bridge/core/services/local_account_data.dart';
import 'package:skill_bridge/core/services/local_account_data_cleanup.dart';
import 'package:skill_bridge/core/services/offline_cache_service.dart';
import 'package:skill_bridge/core/services/offline_outbox_service.dart';

import '../helpers/job_fixtures.dart';

void main() {
  group('LocalAccountData.clear', () {
    late Directory dir;
    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('sb_local_account_');
      Hive.init(dir.path);
      await Hive.openBox<String>('skillbridge_offline_outbox');
      await Hive.openBox('skillbridge_offline_cache');
      await Hive.openBox(HiveService.authBoxName);
      await Hive.openBox(HiveService.searchHistoryBoxName);
      await Hive.openBox(HiveService.settingsBoxName);
    });
    tearDownAll(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('removes cached listings, queued actions, searches and the auth cache; keeps the theme', () async {
      await OfflineCacheService.init();
      await OfflineCacheService.save('jobs_feed', [
        {'id': 'j1'},
      ]);
      await OfflineOutboxService.enqueue(type: 'FIRESTORE_BATCH', payload: {'writes': []}, idempotencyKey: 'k');
      await Hive.box(HiveService.searchHistoryBoxName).put('q', 'plumber');
      await Hive.box(HiveService.authBoxName).put('x', 'y');
      await Hive.box(HiveService.settingsBoxName).put('theme_mode', 'dark');

      await LocalAccountData.clear();

      expect(OfflineCacheService.read('jobs_feed'), isNull);
      expect(OfflineOutboxService.pendingCount(), 0);
      expect(Hive.box(HiveService.searchHistoryBoxName).isEmpty, isTrue);
      expect(Hive.box(HiveService.authBoxName).isEmpty, isTrue);
      expect(Hive.box(HiveService.settingsBoxName).get('theme_mode'), 'dark');
    });
  });

  group('AccountChangeWatcher', () {
    late int clears;
    late AccountChangeWatcher w;
    setUp(() {
      clears = 0;
      w = AccountChangeWatcher(() => clears++);
    });

    test('app start (signed out or signed in) does not clear', () {
      w.update(const AsyncLoading());
      w.update(const AsyncData(null));
      w.update(AsyncData(testUser('a')));
      expect(clears, 0);
    });

    test('signing out clears once', () {
      w.update(AsyncData(testUser('a')));
      w.update(const AsyncData(null));
      w.update(const AsyncData(null));
      expect(clears, 1);
    });

    test('switching to another account clears', () {
      w.update(AsyncData(testUser('a')));
      w.update(AsyncData(testUser('b', role: 'worker')));
      expect(clears, 1);
    });

    test('a reload, an error, or the same account again never clears', () {
      w.update(AsyncData(testUser('a')));
      w.update(const AsyncLoading());
      w.update(AsyncError(Exception('offline'), StackTrace.empty));
      w.update(AsyncData(testUser('a', name: 'Renamed')));
      expect(clears, 0);
    });
  });
}

import 'package:hive_flutter/hive_flutter.dart';
import 'package:skill_bridge/core/services/hive_service.dart';
import 'package:skill_bridge/core/services/offline_cache_service.dart';
import 'package:skill_bridge/core/services/offline_outbox_service.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Data this device keeps for the signed-in account, removed when that
/// account signs out or another account signs in (PRIVACY_POLICY.md §21):
/// cached listings, queued offline actions, recent searches and the auth
/// cache box. Device preferences (theme) stay.
///
/// Queued actions belong to the account that made them; the next account
/// could never send them anyway (the security rules check the sender).
abstract final class LocalAccountData {
  static const _boxes = [HiveService.authBoxName, HiveService.searchHistoryBoxName];

  static Future<void> clear() async {
    Future<void> attempt(String what, Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        Logger.w('Local data: could not clear $what ($e)');
      }
    }

    await Future.wait([
      attempt('offline cache', OfflineCacheService.clear),
      attempt('offline outbox', OfflineOutboxService.clear),
      for (final name in _boxes)
        attempt(name, () async {
          if (Hive.isBoxOpen(name)) await Hive.box(name).clear();
        }),
    ]);
  }
}

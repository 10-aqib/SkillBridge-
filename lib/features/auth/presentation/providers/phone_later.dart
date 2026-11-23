import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skill_bridge/core/services/hive_service.dart';

/// Accounts (by uid) whose owner tapped "Add later" on the phone number step.
/// They are not held on that step; they can add the number from their
/// profile whenever they like. Remembered on this device (settings box, which
/// survives sign-out).
class PhoneLater extends Notifier<Set<String>> {
  static const _key = 'phoneLaterUids';

  @override
  Set<String> build() {
    try {
      final saved = Hive.box(HiveService.settingsBoxName).get(_key);
      if (saved is List) return {...saved.whereType<String>()};
    } catch (_) {}
    return const {};
  }

  void defer(String uid) {
    state = {...state, uid};
    try {
      Hive.box(HiveService.settingsBoxName).put(_key, state.toList());
    } catch (_) {}
  }
}

final phoneLaterProvider = NotifierProvider<PhoneLater, Set<String>>(PhoneLater.new);

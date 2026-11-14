import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while navigating (foreground only: navigation pauses
/// in the background instead of tracking there). Behind an interface for tests.
abstract class ScreenAwake {
  Future<void> keepOn();
  Future<void> allowOff();
}

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();

  @override
  Future<void> keepOn() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      Logger.w('[Navigation] keep screen on failed: $e');
    }
  }

  @override
  Future<void> allowOff() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      Logger.w('[Navigation] release screen failed: $e');
    }
  }
}

final screenAwakeProvider = Provider<ScreenAwake>((ref) => const WakelockScreenAwake());

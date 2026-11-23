import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/services/local_account_data.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';

/// Decides when to clear: only when a settled signed-in account changes to
/// signed out or to a different account. Loading and error states (for
/// example a profile reload) never count as signing out.
class AccountChangeWatcher {
  AccountChangeWatcher(this.onAccountLeft);

  final void Function() onAccountLeft;
  String? _lastUid;

  void update(AsyncValue<UserEntity?> state) {
    if (state.isLoading || state.hasError) return;
    final uid = state.value?.uid;
    if (_lastUid != null && uid != _lastUid) onAccountLeft();
    _lastUid = uid;
  }
}

/// Watched by the app root.
final localAccountDataCleanupProvider = Provider<void>((ref) {
  final watcher = AccountChangeWatcher(() => LocalAccountData.clear());
  ref.listen<AsyncValue<UserEntity?>>(authStateProvider, (_, next) => watcher.update(next), fireImmediately: true);
});

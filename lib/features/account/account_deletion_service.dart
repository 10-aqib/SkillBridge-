import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Why an account couldn't be deleted.
enum AccountDeletionProblem {
  /// Signed in too long ago: sign in again, then delete.
  recentLoginRequired,

  /// A contract is still active: finish or cancel it first.
  activeContracts,

  /// The server function isn't deployed (or not set up).
  notAvailable,

  /// No connection.
  offline,

  /// Anything else; nothing was removed from the sign-in.
  failed,
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.problem);
  final AccountDeletionProblem problem;
  @override
  String toString() => 'AccountDeletionException($problem)';
}

/// In-app account deletion (Phase G6; Google Play requires it). The work is
/// done by the trusted `deleteAccount` function: it deletes the person's own
/// data and sign-in and anonymises shared history ("Deleted user").
class AccountDeletionService {
  AccountDeletionService(this._functions);
  final FirebaseFunctions Function() _functions;

  /// Problem for a function error code and message.
  static AccountDeletionProblem problemFor(String code, String? message) => switch (code) {
        'failed-precondition' when (message ?? '').contains('recent-login') => AccountDeletionProblem.recentLoginRequired,
        'failed-precondition' when (message ?? '').contains('active-contracts') => AccountDeletionProblem.activeContracts,
        'unauthenticated' => AccountDeletionProblem.recentLoginRequired,
        'not-found' || 'unimplemented' => AccountDeletionProblem.notAvailable,
        'unavailable' || 'deadline-exceeded' => AccountDeletionProblem.offline,
        _ => AccountDeletionProblem.failed,
      };

  Future<void> deleteMyAccount() async {
    final FirebaseFunctions functions;
    try {
      functions = _functions();
    } catch (_) {
      throw const AccountDeletionException(AccountDeletionProblem.notAvailable);
    }
    try {
      await functions.httpsCallable('deleteAccount', options: HttpsCallableOptions(timeout: const Duration(seconds: 120))).call<Object?>();
    } on FirebaseFunctionsException catch (e) {
      Logger.w('[Account] delete refused: ${e.code}');
      throw AccountDeletionException(problemFor(e.code, e.message));
    } catch (e) {
      Logger.w('[Account] delete failed: ${e.runtimeType}');
      throw const AccountDeletionException(AccountDeletionProblem.offline);
    }
  }
}

final accountDeletionServiceProvider =
    Provider<AccountDeletionService>((ref) => AccountDeletionService(() => ref.read(firebaseFunctionsProvider)));

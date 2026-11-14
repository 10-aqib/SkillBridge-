/// Role values stored on `users/{uid}.role`.
abstract final class UserRoles {
  static const String client = 'client';
  static const String worker = 'worker';

  /// Roles a person can choose for themselves. Staff roles ('admin',
  /// 'SUPER_ADMIN') are granted only by server-side tooling and are rejected
  /// by the app and by Firestore rules.
  static const Set<String> selfService = {client, worker};

  static bool isSelfService(String? role) => selfService.contains(role);
}

/// Error codes the auth layer raises for flow decisions (not failures the user
/// caused). The UI routes on these instead of showing an error.
abstract final class AuthFlowCodes {
  /// Signed in with Firebase, but no SkillBridge profile exists yet
  /// (new Google account, or an interrupted registration). Ask for a role.
  static const String needsRole = 'needs-role';
}

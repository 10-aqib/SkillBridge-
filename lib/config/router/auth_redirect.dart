import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/constants/app_constants.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

/// Signed-out screens. OTP is not one of them: it verifies the signed-in
/// person's phone, so it must stay reachable once logged in.
const Set<String> kAuthRoutes = {
  RouteNames.welcomePath,
  RouteNames.loginPath,
  RouteNames.signupPath,
  RouteNames.forgotPasswordPath,
  RouteNames.roleSelectionPath,
};

/// Legal pages anyone can open, signed in or not (linked from Welcome and
/// Sign up, which signed-out people see).
const Set<String> kPublicRoutes = {
  RouteNames.termsAndConditionsPath,
  RouteNames.privacyPolicyPath,
};

/// True for "/worker" and "/worker/…", but not "/worker-profile/…" (the public
/// worker profile clients open).
bool _inArea(String location, String area) => location == area || location.startsWith('$area/');

/// Everything [resolveAuthRedirect] depends on. The router re-runs redirects
/// only when this changes, so ordinary profile saves (photo, address…) don't
/// disturb the screen stack.
String authRedirectKey({required bool isLoading, required UserEntity? user}) {
  if (isLoading) return 'loading';
  if (user == null) return 'signed-out';
  return [user.uid, user.role, user.isActive, user.needsClientOnboarding, user.isWorkerProfileComplete, user.isPhoneVerified]
      .join('|');
}

/// True when a client or worker still has to add a phone number confirmed by
/// SMS code. Staff, and people who haven't picked a role yet, are not asked.
bool needsVerifiedPhone(UserEntity user, {bool required = AppConstants.requireVerifiedPhone}) =>
    required && (user.isClient || user.isWorker) && !user.isPhoneVerified;

/// Where a signed-in person starts: onboarding or profile setup first, then
/// their home.
String homePathFor(UserEntity user) {
  if (user.isClient) {
    return user.needsClientOnboarding ? RouteNames.clientOnboardingPath : RouteNames.clientHomePath;
  }
  if (user.isWorker) {
    return user.isWorkerProfileComplete ? RouteNames.workerHomePath : RouteNames.workerProfileSetupPath;
  }
  if (user.isAdmin) return RouteNames.adminDashboardPath;
  return RouteNames.roleSelectionPath;
}

/// Role-aware routing decision, separated from GoRouter so every guard can be
/// unit-tested. Returns the path to redirect to, or null to stay.
///
/// [requirePhone] defaults to [AppConstants.requireVerifiedPhone].
String? resolveAuthRedirect({
  required bool isLoading,
  required UserEntity? user,
  required String location,
  bool requirePhone = AppConstants.requireVerifiedPhone,
}) {
  final isOnSplash = location == RouteNames.splashPath;
  if (isLoading) return isOnSplash ? null : RouteNames.splashPath;
  if (kPublicRoutes.contains(location)) return null;

  final isLoggedIn = user != null;
  final isOnAuthRoute = kAuthRoutes.contains(location);

  if (!isLoggedIn) {
    return (isOnAuthRoute || isOnSplash) ? null : RouteNames.welcomePath;
  }

  // Suspended/inactive accounts can only see signed-out screens.
  if (!user.isActive) return isOnAuthRoute ? null : RouteNames.loginPath;

  final needsPhone = needsVerifiedPhone(user, required: requirePhone);

  if (isOnAuthRoute || isOnSplash) {
    if (needsPhone) return RouteNames.phoneRequiredPath;
    final home = homePathFor(user);
    // Role not chosen yet (e.g. legacy Google sign-up stored '').
    return location == home ? null : home;
  }

  // Phone number first (e.g. right after Google sign-in): only the number
  // and code screens are open until it is confirmed.
  if (needsPhone) {
    return (location == RouteNames.phoneRequiredPath || location == RouteNames.otpPath) ? null : RouteNames.phoneRequiredPath;
  }
  if (location == RouteNames.phoneRequiredPath) return homePathFor(user);

  // Cross-role protection.
  if (user.isClient && _inArea(location, '/worker')) return RouteNames.clientHomePath;
  if (user.isWorker && _inArea(location, '/client')) return RouteNames.workerHomePath;
  if (!user.isAdmin && _inArea(location, '/admin')) {
    return user.isClient ? RouteNames.clientHomePath : RouteNames.workerHomePath;
  }
  if (!user.isClient && !user.isWorker && !user.isAdmin) return RouteNames.roleSelectionPath;

  return null;
}

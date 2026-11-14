import 'package:skill_bridge/config/router/route_names.dart';
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

/// True for "/worker" and "/worker/…", but not "/worker-profile/…" (the public
/// worker profile clients open).
bool _inArea(String location, String area) => location == area || location.startsWith('$area/');

/// Everything [resolveAuthRedirect] depends on. The router re-runs redirects
/// only when this changes, so ordinary profile saves (photo, address…) don't
/// disturb the screen stack.
String authRedirectKey({required bool isLoading, required UserEntity? user}) {
  if (isLoading) return 'loading';
  if (user == null) return 'signed-out';
  return [user.uid, user.role, user.isActive, user.needsClientOnboarding, user.isWorkerProfileComplete].join('|');
}

/// Role-aware routing decision, separated from GoRouter so every guard can be
/// unit-tested. Returns the path to redirect to, or null to stay.
String? resolveAuthRedirect({
  required bool isLoading,
  required UserEntity? user,
  required String location,
}) {
  final isOnSplash = location == RouteNames.splashPath;
  if (isLoading) return isOnSplash ? null : RouteNames.splashPath;

  final isLoggedIn = user != null;
  final isOnAuthRoute = kAuthRoutes.contains(location);

  if (!isLoggedIn) {
    return (isOnAuthRoute || isOnSplash) ? null : RouteNames.welcomePath;
  }

  // Suspended/inactive accounts can only see signed-out screens.
  if (!user.isActive) return isOnAuthRoute ? null : RouteNames.loginPath;

  if (isOnAuthRoute || isOnSplash) {
    if (user.isClient) {
      return user.needsClientOnboarding ? RouteNames.clientOnboardingPath : RouteNames.clientHomePath;
    }
    if (user.isWorker) {
      return user.isWorkerProfileComplete ? RouteNames.workerHomePath : RouteNames.workerProfileSetupPath;
    }
    if (user.isAdmin) return RouteNames.adminDashboardPath;
    // Role not chosen yet (e.g. legacy Google sign-up stored '').
    return location == RouteNames.roleSelectionPath ? null : RouteNames.roleSelectionPath;
  }

  // Cross-role protection.
  if (user.isClient && _inArea(location, '/worker')) return RouteNames.clientHomePath;
  if (user.isWorker && _inArea(location, '/client')) return RouteNames.workerHomePath;
  if (!user.isAdmin && _inArea(location, '/admin')) {
    return user.isClient ? RouteNames.clientHomePath : RouteNames.workerHomePath;
  }
  if (!user.isClient && !user.isWorker && !user.isAdmin) return RouteNames.roleSelectionPath;

  return null;
}

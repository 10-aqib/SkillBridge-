import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/auth_redirect.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/providers/analytics_providers.dart';
import 'package:skill_bridge/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/login_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/otp_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/signup_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/splash_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/welcome_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_onboarding_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/edit_client_profile_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/verification_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_home_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_main_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_profile_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_settings_screen.dart';
import 'package:skill_bridge/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/my_jobs_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/post_job_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/job_details_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_home_screen.dart';
import 'package:skill_bridge/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_main_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_profile_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_profile_setup_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_settings_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/my_proposals_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/contract_details_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/my_contracts_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/submit_work_screen.dart';
import 'package:skill_bridge/features/identity/presentation/identity_verification_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verification_history_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/saved_jobs_screen.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/contract_navigation_screen.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/contract_tracking_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/proposal_details_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/received_proposals_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/submit_proposal_screen.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/reviews/presentation/screens/write_review_screen.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:skill_bridge/features/admin/presentation/screens/admin_jobs_screen.dart';
import 'package:skill_bridge/features/notifications/presentation/screens/notification_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/nearby_workers_screen.dart';
import 'package:skill_bridge/features/payments/presentation/screens/easypaisa_checkout_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/worker_profile_detail_screen.dart';
import 'package:skill_bridge/shared/screens/terms_and_conditions_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);

  // The router is built once. Auth state includes the profile document, so
  // watching it here rebuilt the router on every profile save and sent people
  // back to the start (e.g. Edit profile → Save landed on Home, and worker
  // setup restarted after each step). Re-run the redirect only when something
  // it depends on changes; refreshing on every save duplicated pushed pages.
  final authChanged = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (previous, next) {
    String key(AsyncValue<UserEntity?>? s) =>
        s == null ? '' : authRedirectKey(isLoading: s.isLoading, user: s.value);
    if (key(previous) != key(next)) authChanged.value++;
  });
  ref.onDispose(authChanged.dispose);

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteNames.splashPath,
    observers: [
      analyticsService.getAnalyticsObserver(),
    ],
    debugLogDiagnostics: false,
    refreshListenable: authChanged,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      return resolveAuthRedirect(
        isLoading: authState.isLoading,
        user: authState.value,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        name: RouteNames.splashName,
        path: RouteNames.splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: RouteNames.loginName,
        path: RouteNames.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: RouteNames.welcomeName,
        path: RouteNames.welcomePath,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        name: RouteNames.signupName,
        path: RouteNames.signupPath,
        builder: (context, state) =>
            SignupScreen(initialRole: state.uri.queryParameters['role']),
      ),
      GoRoute(
        name: RouteNames.otpName,
        path: RouteNames.otpPath,
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return OtpVerificationScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        name: RouteNames.forgotPasswordName,
        path: RouteNames.forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: RouteNames.roleSelectionName,
        path: RouteNames.roleSelectionPath,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      // Client Shell (Stateful)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ClientMainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.clientHomeName,
                path: RouteNames.clientHomePath,
                builder: (context, state) => const ClientHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.clientJobsName,
                path: RouteNames.clientJobsPath,
                builder: (context, state) => const MyJobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.clientChatsName,
                path: RouteNames.clientChatsPath,
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.clientProfileName,
                path: RouteNames.clientProfilePath,
                builder: (context, state) => const ClientProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: RouteNames.clientOnboardingName,
        path: RouteNames.clientOnboardingPath,
        builder: (context, state) => const ClientOnboardingScreen(),
      ),
      GoRoute(
        name: RouteNames.clientEditProfileName,
        path: RouteNames.clientEditProfilePath,
        builder: (context, state) => const EditClientProfileScreen(),
      ),
      GoRoute(
        name: RouteNames.workerVerificationName,
        path: RouteNames.workerVerificationPath,
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        name: RouteNames.clientSettingsName,
        path: RouteNames.clientSettingsPath,
        builder: (context, state) => const ClientSettingsScreen(),
      ),
      GoRoute(
        name: RouteNames.clientPostJobName,
        path: RouteNames.clientPostJobPath,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PostJobScreen(
            workerId: extra?['workerId'] as String?,
            workerName: extra?['workerName'] as String?,
          );
        },
      ),
      // Kept for old links; the shared /jobs/:jobId route is used now.
      GoRoute(
        name: RouteNames.clientJobDetailsName,
        path: RouteNames.clientJobDetailsPath,
        builder: (context, state) => JobDetailsScreen(
          jobId: state.pathParameters['jobId']!,
          initial: state.extra as JobEntity?,
        ),
      ),
      GoRoute(
        name: RouteNames.jobDetailsName,
        path: RouteNames.jobDetailsPath,
        builder: (context, state) => JobDetailsScreen(
          jobId: state.pathParameters['jobId']!,
          initial: state.extra as JobEntity?,
        ),
      ),
      GoRoute(
        name: RouteNames.jobEditName,
        path: RouteNames.jobEditPath,
        builder: (context, state) => EditJobScreen(
          jobId: state.pathParameters['jobId']!,
          initial: state.extra as JobEntity?,
        ),
      ),
      GoRoute(
        name: RouteNames.jobProposeName,
        path: RouteNames.jobProposePath,
        builder: (context, state) => SubmitProposalScreen(
          jobId: state.pathParameters['jobId']!,
          initialJob: state.extra is JobEntity ? state.extra as JobEntity : null,
        ),
      ),
      GoRoute(
        name: RouteNames.jobProposalsName,
        path: RouteNames.jobProposalsPath,
        builder: (context, state) => ReceivedProposalsScreen(
          jobId: state.pathParameters['jobId']!,
          initialJob: state.extra is JobEntity ? state.extra as JobEntity : null,
        ),
      ),
      GoRoute(
        name: RouteNames.workerJobFeedName,
        path: RouteNames.workerJobFeedPath,
        builder: (context, state) => const JobFeedScreen(),
      ),
      GoRoute(
        name: RouteNames.identityName,
        path: RouteNames.identityPath,
        builder: (context, state) => const IdentityVerificationScreen(),
      ),
      GoRoute(
        name: RouteNames.identityHistoryName,
        path: RouteNames.identityHistoryPath,
        builder: (context, state) => const VerificationHistoryScreen(),
      ),
      GoRoute(
        name: RouteNames.workerSavedJobsName,
        path: RouteNames.workerSavedJobsPath,
        builder: (context, state) => const SavedJobsScreen(),
      ),
      // Worker Shell (Stateful)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return WorkerMainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.workerHomeName,
                path: RouteNames.workerHomePath,
                builder: (context, state) => const WorkerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.workerProposalsName,
                path: RouteNames.workerProposalsPath,
                builder: (context, state) => const MyProposalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.workerContractsName,
                path: RouteNames.workerContractsPath,
                builder: (context, state) => const MyContractsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.workerChatsName,
                path: RouteNames.workerChatsPath,
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.workerProfileName,
                path: RouteNames.workerProfilePath,
                builder: (context, state) => WorkerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: RouteNames.workerProfileSetupName,
        path: RouteNames.workerProfileSetupPath,
        builder: (context, state) => WorkerProfileSetupScreen(
          // ?step=3 edits one section of an existing profile.
          initialStep: int.tryParse(state.uri.queryParameters['step'] ?? ''),
        ),
      ),
      GoRoute(
        name: RouteNames.workerSettingsName,
        path: RouteNames.workerSettingsPath,
        builder: (context, state) => const WorkerSettingsScreen(),
      ),
      GoRoute(
        name: RouteNames.proposalDetailsName,
        path: RouteNames.proposalDetailsPath,
        builder: (context, state) => ProposalDetailsScreen(
          proposalId: state.pathParameters['proposalId']!,
          initial: state.extra is ProposalEntity ? state.extra as ProposalEntity : null,
        ),
      ),
      GoRoute(
        name: RouteNames.contractDetailsName,
        path: RouteNames.contractDetailsPath,
        builder: (context, state) => ContractDetailsScreen(
          contractId: state.pathParameters['contractId']!,
          initial: state.extra is ContractEntity ? state.extra as ContractEntity : null,
        ),
      ),
      GoRoute(
        name: RouteNames.contractNavigateName,
        path: RouteNames.contractNavigatePath,
        builder: (context, state) => ContractNavigationScreen(contractId: state.pathParameters['contractId']!),
      ),
      GoRoute(
        name: RouteNames.contractTrackName,
        path: RouteNames.contractTrackPath,
        builder: (context, state) => ContractTrackingScreen(contractId: state.pathParameters['contractId']!),
      ),
      GoRoute(
        name: RouteNames.contractSubmitName,
        path: RouteNames.contractSubmitPath,
        builder: (context, state) => SubmitWorkScreen(
          contractId: state.pathParameters['contractId']!,
          initial: state.extra is ContractEntity ? state.extra as ContractEntity : null,
        ),
      ),
      // Clients reach their contracts from My jobs and from each hired job.
      GoRoute(
        name: RouteNames.clientContractsName,
        path: RouteNames.clientContractsPath,
        builder: (context, state) => const MyContractsScreen(),
      ),
      GoRoute(
        name: RouteNames.termsAndConditionsName,
        path: RouteNames.termsAndConditionsPath,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        name: RouteNames.chatRoomName,
        path: RouteNames.chatRoomPath,
        // Opened by id (from the list, a notification or a deep link); the
        // screen loads the conversation itself and shows its own states.
        builder: (context, state) => ChatRoomScreen(chatId: state.pathParameters['chatId'] ?? ''),
      ),
      // Admin Routes
      GoRoute(
        name: RouteNames.adminDashboardName,
        path: RouteNames.adminDashboardPath,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        name: RouteNames.adminUsersName,
        path: RouteNames.adminUsersPath,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        name: RouteNames.adminJobsName,
        path: RouteNames.adminJobsPath,
        builder: (context, state) => const AdminJobsScreen(),
      ),
      GoRoute(
        name: RouteNames.writeReviewName,
        path: RouteNames.writeReviewPath,
        builder: (context, state) {
          final contract = state.extra as ContractEntity;
          return WriteReviewScreen(contract: contract);
        },
      ),
      // Notification screens
      GoRoute(
        name: RouteNames.clientNotificationsName,
        path: RouteNames.clientNotificationsPath,
        builder: (context, state) => NotificationScreen(),
      ),
      GoRoute(
        name: RouteNames.easyPaisaCheckoutName,
        path: RouteNames.easyPaisaCheckoutPath,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return EasyPaisaCheckoutScreen(
            jobId: extra['jobId'] as String,
            amount: extra['amount'] as double,
            workerName: extra['workerName'] as String,
          );
        },
      ),
      GoRoute(
        name: RouteNames.workerNotificationsName,
        path: RouteNames.workerNotificationsPath,
        builder: (context, state) => NotificationScreen(),
      ),
      GoRoute(
        name: RouteNames.clientNearbyWorkersName,
        path: RouteNames.clientNearbyWorkersPath,
        builder: (context, state) => NearbyWorkersScreen(),
      ),
      GoRoute(
        name: RouteNames.publicWorkerProfileName,
        path: RouteNames.publicWorkerProfilePath,
        builder: (context, state) {
          final workerId = state.pathParameters['workerId']!;
          return WorkerProfileDetailScreen(workerId: workerId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(RouteNames.splashPath),
              child: Text(MaterialLocalizations.of(context).backButtonTooltip),
            ),
          ],
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

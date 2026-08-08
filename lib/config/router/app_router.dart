import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/providers/analytics_providers.dart';
import 'package:skill_bridge/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/login_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/otp_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/signup_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/splash_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_home_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_main_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_profile_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_settings_screen.dart';
import 'package:skill_bridge/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/my_jobs_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/post_job_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/job_details_screen.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_home_screen.dart';
import 'package:skill_bridge/features/chat/data/models/chat_model.dart';
import 'package:skill_bridge/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_main_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_profile_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_profile_setup_screen.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_settings_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/my_proposals_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/my_contracts_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/proposal_details_screen.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/reviews/presentation/screens/write_review_screen.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:skill_bridge/features/admin/presentation/screens/admin_jobs_screen.dart';
import 'package:skill_bridge/features/notifications/presentation/screens/notification_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/nearby_workers_screen.dart';
import 'package:skill_bridge/features/payments/presentation/screens/easypaisa_checkout_screen.dart';
import 'package:skill_bridge/features/client/presentation/screens/worker_profile_detail_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state for reactive redirects
  final authState = ref.watch(authStateProvider);

  final analyticsService = ref.watch(analyticsServiceProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteNames.splashPath,
    observers: [
      analyticsService.getAnalyticsObserver(),
    ],
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isOnSplash = state.matchedLocation == RouteNames.splashPath;

      // While auth state is loading, keep on splash
      if (authState.isLoading) return isOnSplash ? null : RouteNames.splashPath;

      final user = authState.value;
      final isLoggedIn = user != null;

      final isOnAuthRoute = [
        RouteNames.loginPath,
        RouteNames.signupPath,
        RouteNames.forgotPasswordPath,
        RouteNames.roleSelectionPath,
        RouteNames.otpPath,
      ].contains(state.matchedLocation);

      // Unauthenticated user trying to access protected routes
      if (!isLoggedIn && !isOnAuthRoute && !isOnSplash) {
        return RouteNames.loginPath;
      }

      // Block suspended/inactive accounts
      if (isLoggedIn && !user.isActive) {
        if (!isOnAuthRoute) {
          return RouteNames.loginPath;
        }
        return null;
      }

      // Authenticated user on auth/splash routes → redirect to their home
      if (isLoggedIn && (isOnAuthRoute || isOnSplash)) {
        if (user.isClient) return RouteNames.clientHomePath;
        if (user.isWorker) {
          return user.isWorkerProfileComplete
              ? RouteNames.workerHomePath
              : RouteNames.workerProfileSetupPath;
        }
        if (user.isAdmin) return RouteNames.adminDashboardPath;
        // Fallback for new account without role
        return RouteNames.roleSelectionPath;
      }

      // Prevent cross-role route access
      if (isLoggedIn) {
        final location = state.matchedLocation;
        if (user.isClient && location.startsWith('/worker')) {
          return RouteNames.clientHomePath;
        }
        if (user.isWorker && location.startsWith('/client')) {
          return RouteNames.workerHomePath;
        }
        if (!user.isAdmin && location.startsWith('/admin')) {
          return user.isClient
              ? RouteNames.clientHomePath
              : RouteNames.workerHomePath;
        }
        if (!user.isClient && !user.isWorker && !user.isAdmin && !isOnAuthRoute) {
          return RouteNames.roleSelectionPath;
        }
      }

      return null; // No redirect
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
        name: RouteNames.signupName,
        path: RouteNames.signupPath,
        builder: (context, state) => const SignupScreen(),
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
        name: RouteNames.clientSettingsName,
        path: RouteNames.clientSettingsPath,
        builder: (context, state) => const ClientSettingsScreen(),
      ),
      GoRoute(
        name: RouteNames.clientPostJobName,
        path: RouteNames.clientPostJobPath,
        builder: (context, state) => const PostJobScreen(),
      ),
      GoRoute(
        name: RouteNames.clientJobDetailsName,
        path: RouteNames.clientJobDetailsPath,
        builder: (context, state) {
          final job = state.extra as JobEntity?;
          return JobDetailsScreen(job: job);
        },
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
                builder: (context, state) => const WorkerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: RouteNames.workerProfileSetupName,
        path: RouteNames.workerProfileSetupPath,
        builder: (context, state) => const WorkerProfileSetupScreen(),
      ),
      GoRoute(
        name: RouteNames.workerSettingsName,
        path: RouteNames.workerSettingsPath,
        builder: (context, state) => const WorkerSettingsScreen(),
      ),
      GoRoute(
        name: RouteNames.proposalDetailsName,
        path: RouteNames.proposalDetailsPath,
        builder: (context, state) {
          final proposal = state.extra as ProposalEntity?;
          return ProposalDetailsScreen(proposal: proposal);
        },
      ),
      GoRoute(
        name: RouteNames.chatRoomName,
        path: RouteNames.chatRoomPath,
        builder: (context, state) {
          final chat = state.extra as ChatModel;
          return ChatRoomScreen(chat: chat);
        },
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
        builder: (context, state) => const NotificationScreen(),
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
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        name: RouteNames.clientNearbyWorkersName,
        path: RouteNames.clientNearbyWorkersPath,
        builder: (context, state) => const NearbyWorkersScreen(),
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
              onPressed: () => context.go(RouteNames.loginPath),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

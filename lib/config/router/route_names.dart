class RouteNames {
  static const String splashName = 'splash';
  static const String splashPath = '/';

  static const String loginName = 'login';
  static const String loginPath = '/login';

  static const String signupName = 'signup';
  static const String signupPath = '/signup';

  static const String otpName = 'otp';
  static const String otpPath = '/otp';
  // Required phone number step (after sign-up or Google sign-in).
  static const String phoneRequiredName = 'phoneRequired';
  static const String phoneRequiredPath = '/add-phone';
  // "Get verified" hub (CNIC documents + NADRA fingerprint), both roles.
  static const String getVerifiedName = 'getVerified';
  static const String getVerifiedPath = '/get-verified';
  static const String cnicVerificationName = 'cnicVerification';
  static const String cnicVerificationPath = '/get-verified/cnic';

  static const String forgotPasswordName = 'forgotPassword';
  static const String forgotPasswordPath = '/forgot-password';

  static const String roleSelectionName = 'roleSelection';
  static const String roleSelectionPath = '/role-selection';

  static const String welcomeName = 'welcome';
  static const String welcomePath = '/welcome';

  static const String clientOnboardingName = 'clientOnboarding';
  static const String clientOnboardingPath = '/client/onboarding';

  static const String clientEditProfileName = 'clientEditProfile';
  static const String clientEditProfilePath = '/client/profile/edit';

  static const String workerVerificationName = 'workerVerification';
  static const String workerVerificationPath = '/worker/verification';

  // Client Shell
  static const String clientHomeName = 'clientHome';
  static const String clientHomePath = '/client/home';

  static const String clientSearchName = 'clientSearch';
  static const String clientSearchPath = '/client/search';

  static const String clientPostJobName = 'clientPostJob';
  static const String clientPostJobPath = '/client/post-job';

  static const String clientChatsName = 'clientChats';
  static const String clientChatsPath = '/client/chats';

  static const String clientProfileName = 'clientProfile';
  static const String clientProfilePath = '/client/profile';

  static const String clientSettingsName = 'clientSettings';
  static const String clientSettingsPath = '/client/settings';

  static const String clientJobsName = 'clientJobs';
  static const String clientJobsPath = '/client/jobs';

  static const String clientJobDetailsName = 'clientJobDetails';
  static const String clientJobDetailsPath = '/client/jobs/:jobId';

  /// Shared job details (clients and workers), loaded by id.
  static const String jobDetailsName = 'jobDetails';
  static const String jobDetailsPath = '/jobs/:jobId';
  static String jobDetailsLocation(String jobId) => '/jobs/$jobId';

  /// Edit an open job (owner only).
  static const String jobEditName = 'jobEdit';
  static const String jobEditPath = '/jobs/:jobId/edit';
  static String jobEditLocation(String jobId) => '/jobs/$jobId/edit';

  // Worker sends (or re-sends) a proposal for a job.
  static const String jobProposeName = 'jobPropose';
  static const String jobProposePath = '/jobs/:jobId/propose';
  static String jobProposeLocation(String jobId) => '/jobs/$jobId/propose';

  // Client reviews the proposals received for one of their jobs.
  static const String jobProposalsName = 'jobProposals';
  static const String jobProposalsPath = '/jobs/:jobId/proposals';
  static String jobProposalsLocation(String jobId) => '/jobs/$jobId/proposals';

  /// Worker job discovery feed.
  static const String workerJobFeedName = 'workerJobFeed';
  static const String workerJobFeedPath = '/worker/jobs';

  // NADRA track: identity verification (workers and hirers alike).
  static const String identityName = 'identity';
  static const String identityPath = '/identity';
  static const String identityHistoryName = 'identityHistory';
  static const String identityHistoryPath = '/identity/history';

  // Phase G6: the worker's bookmarked jobs.
  static const String workerSavedJobsName = 'workerSavedJobs';
  static const String workerSavedJobsPath = '/worker/saved-jobs';

  static const String clientContractsName = 'clientContracts';
  static const String clientContractsPath = '/client/contracts';

  static const String clientContractDetailsName = 'clientContractDetails';
  static const String clientContractDetailsPath = '/client/contracts/:contractId';

  static const String clientNotificationsName = 'clientNotifications';
  static const String clientNotificationsPath = '/client/notifications';

  static const String clientNearbyWorkersName = 'clientNearbyWorkers';
  static const String clientNearbyWorkersPath = '/client/nearby-workers';

  // Worker Shell
  static const String workerHomeName = 'workerHome';
  static const String workerHomePath = '/worker/home';

  static const String workerSearchName = 'workerSearch';
  static const String workerSearchPath = '/worker/search';

  static const String workerChatsName = 'workerChats';
  static const String workerChatsPath = '/worker/chats';

  static const String workerProfileName = 'workerProfile';
  static const String workerProfilePath = '/worker/profile';

  static const String workerProfileSetupName = 'workerProfileSetup';
  static const String workerProfileSetupPath = '/worker/profile/setup';

  static const String workerSettingsName = 'workerSettings';
  static const String workerSettingsPath = '/worker/settings';

  static const String workerProposalsName = 'workerProposals';
  static const String workerProposalsPath = '/worker/proposals';

  static const String proposalDetailsName = 'proposalDetails';
  static const String proposalDetailsPath = '/proposals/:proposalId';
  static String proposalDetailsLocation(String proposalId) => '/proposals/$proposalId';

  // One contract, for its client or worker (Phase 4A).
  static const String contractDetailsName = 'contractDetails';
  static const String contractDetailsPath = '/contracts/:contractId';
  static String contractDetailsLocation(String contractId) => '/contracts/$contractId';

  // The hired worker submits the work for review.
  static const String contractSubmitName = 'contractSubmit';
  static const String contractSubmitPath = '/contracts/:contractId/submit';
  static String contractSubmitLocation(String contractId) => '/contracts/$contractId/submit';

  // Navigation phase 9: the hired worker's directions to the job, and the
  // client's live map of the worker. Both check the signed-in party.
  static const String contractNavigateName = 'contractNavigate';
  static const String contractNavigatePath = '/contracts/:contractId/navigate';
  static String contractNavigateLocation(String contractId) => '/contracts/$contractId/navigate';

  static const String contractTrackName = 'contractTrack';
  static const String contractTrackPath = '/contracts/:contractId/track';
  static String contractTrackLocation(String contractId) => '/contracts/$contractId/track';

  static const String workerContractsName = 'workerContracts';
  static const String workerContractsPath = '/worker/contracts';

  static const String workerContractDetailsName = 'workerContractDetails';
  static const String workerContractDetailsPath = '/worker/contracts/:contractId';

  static const String workerNotificationsName = 'workerNotifications';
  static const String workerNotificationsPath = '/worker/notifications';

  // Shared Screens
  static const String termsAndConditionsName = 'termsAndConditions';
  static const String termsAndConditionsPath = '/terms-and-conditions';
  static const String privacyPolicyName = 'privacyPolicy';
  static const String privacyPolicyPath = '/privacy-policy';

  static const String chatRoomName = 'chatRoom';
  static const String chatRoomPath = '/chat/:chatId';
  static String chatRoomLocation(String chatId) => '/chat/$chatId';

  static const String publicWorkerProfileName = 'publicWorkerProfile';
  static const String publicWorkerProfilePath = '/worker-profile/:workerId';

  static const String writeReviewName = 'writeReview';
  static const String writeReviewPath = '/review/:contractId';

  // Payments
  static const String easyPaisaCheckoutName = 'easyPaisaCheckout';
  static const String easyPaisaCheckoutPath = '/checkout/easypaisa';

  // Admin Shell (Flutter Web)
  static const String adminDashboardName = 'adminDashboard';
  static const String adminDashboardPath = '/admin/dashboard';

  static const String adminUsersName = 'adminUsers';
  static const String adminUsersPath = '/admin/users';

  static const String adminWorkersName = 'adminWorkers';
  static const String adminWorkersPath = '/admin/workers';

  static const String adminJobsName = 'adminJobs';
  static const String adminJobsPath = '/admin/jobs';

  static const String adminCategoriesName = 'adminCategories';
  static const String adminCategoriesPath = '/admin/categories';

  static const String adminCommissionsName = 'adminCommissions';
  static const String adminCommissionsPath = '/admin/commissions';

  static const String adminDisputesName = 'adminDisputes';
  static const String adminDisputesPath = '/admin/disputes';

  static const String adminAnalyticsName = 'adminAnalytics';
  static const String adminAnalyticsPath = '/admin/analytics';

  static const String adminVerificationName = 'adminVerification';
  static const String adminVerificationPath = '/admin/verification';

  static const String adminNotificationsName = 'adminNotifications';
  static const String adminNotificationsPath = '/admin/notifications';

  static const String adminSettingsName = 'adminSettings';
  static const String adminSettingsPath = '/admin/settings';
}

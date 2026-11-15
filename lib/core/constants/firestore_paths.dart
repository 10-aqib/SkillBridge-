class FirestorePaths {
  static const String users = 'users';

  /// Public view of users/{uid} (no phone, email or addresses). Written by the
  /// owner's app and checked by the rules (PublicProfileSync); read this for
  /// anyone other than the signed-in user.
  static const String publicProfiles = 'publicProfiles';

  /// Rating ledger per person (count, sum, average); moved only with a
  /// new review (free plan, Phase S5).
  static const String ratings = 'ratings';

  /// A worker's live position, readable by the clients of their active jobs.
  /// Written only by Cloud Functions.
  static const String liveLocations = 'liveLocations';
  static const String categories = 'categories';
  static const String skills = 'skills';
  static const String jobs = 'jobs';
  static const String proposals = 'proposals';
  static const String contracts = 'contracts';
  static const String reviews = 'reviews';
  static const String chats = 'chats';
  static const String notifications = 'notifications';
  static const String commissions = 'commissions';
  static const String payments = 'payments';
  static const String disputes = 'disputes';
  static const String appSettings = 'app_settings';

  // Subcollections
  static String messages(String chatId) => '$chats/$chatId/messages';
}

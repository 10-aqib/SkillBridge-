class FirestorePaths {
  static const String users = 'users';
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

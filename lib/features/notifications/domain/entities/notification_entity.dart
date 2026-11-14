class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final bool isRead;

  /// e.g. message, contract_created, work_submitted, revision_requested.
  final String type;

  NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.payload,
    required this.createdAt,
    this.isRead = false,
    this.type = '',
  });

  /// The conversation a message notification is about.
  String? get chatId => payload?['chatId'] as String?;

  /// The contract a contract notification is about.
  String? get contractId => payload?['contractId'] as String?;
}

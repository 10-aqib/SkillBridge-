class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final bool isRead;

  NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.payload,
    required this.createdAt,
    this.isRead = false,
  });
}

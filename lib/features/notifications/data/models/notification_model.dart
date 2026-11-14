import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    super.payload,
    required super.createdAt,
    super.isRead,
    super.type,
  });

  factory NotificationModel.fromSnapshot(DocumentSnapshot snap) {
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    final created = data['createdAt'];
    final payload = data['payload'];
    return NotificationModel(
      id: snap.id,
      userId: (data['userId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      payload: payload is Map ? Map<String, dynamic>.from(payload) : null,
      // A pending server time reads as now until confirmed.
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      type: (data['type'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'payload': payload,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

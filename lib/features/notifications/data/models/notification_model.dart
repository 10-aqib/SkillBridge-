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
  });

  factory NotificationModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return NotificationModel(
      id: snap.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      payload: data['payload'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
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

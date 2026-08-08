import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'notifications';

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromSnapshot(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(_collectionPath)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    await _firestore.collection(_collectionPath).add({
      'userId': userId,
      'title': title,
      'body': body,
      'payload': payload,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}


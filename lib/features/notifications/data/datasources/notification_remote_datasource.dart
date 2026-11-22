import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/notifications/data/models/notification_model.dart';

/// The signed-in person's in-app notifications (Phase G5).
///
/// Notifications are created alongside the action they are about and then
/// checked and worded by the trusted function; the app only reads its own,
/// marks them read (the only change the rules allow) and deletes them.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource([FirebaseFirestore? firestore]) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  static const String _collectionPath = 'notifications';

  /// Newest first; the latest [limit] only (older ones stay stored).
  static const int limit = 100;

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => NotificationModel.fromSnapshot(doc)).toList();
      // Pending server timestamps sort as "now": keep newest first.
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collectionPath).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks every unread notification of [userId] read, in batches.
  Future<int> markAllAsRead(String userId) async {
    final unread = await _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .limit(400)
        .get();
    if (unread.docs.isEmpty) return 0;
    final batch = _firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    return unread.docs.length;
  }

  Future<void> delete(String notificationId) => _firestore.collection(_collectionPath).doc(notificationId).delete();
}

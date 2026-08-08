import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:skill_bridge/features/notifications/data/models/notification_model.dart';

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource();
});

final userNotificationsStreamProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  final datasource = ref.watch(notificationRemoteDataSourceProvider);
  return datasource.getUserNotifications(userId);
});

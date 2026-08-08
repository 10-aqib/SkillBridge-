import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/features/notifications/data/services/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  // Initialize service (fire-and-forget)
  service.init();
  return service;
});

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/app_router.dart';
import 'package:skill_bridge/features/notifications/presentation/notification_routes.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Handles Firebase Cloud Messaging registration and message routing.
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  Future<void> init() async {
    // ── Request permission (Android 13+ & iOS) ──
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    Logger.i('FCM permission: ${settings.authorizationStatus}');

    // ── Keep foreground notifications visible on iOS ──
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── Initialize Local Notifications for Android Foreground ──
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await _localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: (response) {
      final raw = response.payload;
      if (raw == null) return;
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) _routeFromPayload(data);
      } catch (_) {}
    });

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // ── Log and save token ──
    final token = await _messaging.getToken();
    Logger.i('FCM token: $token');
    await _saveTokenToFirestore(token);

    // ── Listen for auth state changes to save token when user logs in ──
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final currentToken = await _messaging.getToken();
        await _saveTokenToFirestore(currentToken);
      }
    });

    // ── Refresh token listener ──
    _messaging.onTokenRefresh.listen((newToken) {
      Logger.i('FCM token refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });

    // ── Foreground messages ──
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.i('Foreground FCM: ${message.notification?.title}');
      
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // ── Background / terminated message tap ──
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.i('Notification tapped (background): ${message.data}');
      _routeFromPayload(message.data);
    });

    // ── App opened from a terminated state ──
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Logger.i('App launched via notification: ${initial.data}');
      _routeFromPayload(initial.data);
    }
  }

  /// Opens the conversation or contract a tapped notification is about
  /// (payload {chatId} or {contractId}, set by the trusted functions). When
  /// the app was just launched, waits briefly for the router.
  void _routeFromPayload(Map<String, dynamic> data, [int attempt = 0]) {
    final route = notificationRouteFor(data);
    if (route == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) {
      if (attempt < 20) Timer(const Duration(milliseconds: 300), () => _routeFromPayload(data, attempt + 1));
      return;
    }
    GoRouter.of(context).push(route);
  }

  // ── Topic helpers ──
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    Logger.i('Subscribed to FCM topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    Logger.i('Unsubscribed from FCM topic: $topic');
  }

  Future<void> saveCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      await _saveTokenToFirestore(token);
    } catch (e) {
      Logger.e('Failed to save current FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        Logger.i('FCM token saved to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      Logger.e('Failed to save FCM token to Firestore: $e');
    }
  }
}

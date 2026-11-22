import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/app_router.dart';
import 'package:skill_bridge/features/notifications/presentation/notification_routes.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Runs when a push arrives while the app is in the background or closed.
/// Messages with a notification part are shown by the system; tapping one
/// opens the app, which then routes through getInitialMessage /
/// onMessageOpenedApp. Nothing else is needed here, but Android requires a
/// registered handler for data delivery in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Push tokens per device (Phase G5): `fcmTokens/{uid}` holds
/// `{tokens: {<token>: {platform, updatedAt}}, updatedAt}`; the rules allow
/// only the owner and at most 10 devices, so the oldest are dropped first.
/// The trusted function sends each notification to all of them and removes
/// tokens Firebase reports as dead.
class PushTokenStore {
  PushTokenStore(this._db);
  final FirebaseFirestore _db;

  static const maxDevices = 10;

  static String get platform => kIsWeb ? 'web' : defaultTargetPlatform.name;

  /// Adds (or refreshes) [token] for [uid]; replaces [previous] if given.
  Future<void> save(String uid, String token, {String? previous}) async {
    final ref = _db.collection('fcmTokens').doc(uid);
    final next = nextTokens((await ref.get()).data()?['tokens'], token, previous: previous);
    await ref.set({'tokens': next, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// The token map after adding [token] (and dropping [previous]): the
  /// [maxDevices] - 1 most recently seen other devices are kept.
  @visibleForTesting
  static Map<String, Object?> nextTokens(Object? current, String token, {String? previous, Object? now}) {
    final entries = <String, Map<String, dynamic>>{};
    if (current is Map) {
      for (final e in current.entries) {
        if (e.key is String && e.value is Map) entries[e.key as String] = Map<String, dynamic>.from(e.value as Map);
      }
    }
    entries.remove(token);
    if (previous != null) entries.remove(previous);
    final kept = entries.entries.toList()
      ..sort((a, b) {
        final ta = a.value['updatedAt'], tb = b.value['updatedAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        if (ta is Timestamp) return -1;
        if (tb is Timestamp) return 1;
        return 0;
      });
    return {
      for (final e in kept.take(maxDevices - 1)) e.key: e.value,
      token: {'platform': platform, 'updatedAt': now ?? FieldValue.serverTimestamp()},
    };
  }

  /// Removes [token] (this device) from [uid]'s list, e.g. on sign-out.
  Future<void> remove(String uid, String token) async {
    if (token.contains('.')) return; // never the case for FCM tokens
    try {
      await _db.collection('fcmTokens').doc(uid).update({'tokens.$token': FieldValue.delete()});
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }

  /// Signs this device out of push for [uid]: best effort, never blocks
  /// signing out for long.
  static Future<void> removeThisDevice(String uid) async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 4));
      if (token != null) await PushTokenStore(FirebaseFirestore.instance).remove(uid, token).timeout(const Duration(seconds: 4));
    } catch (e) {
      Logger.w('Push token not removed on sign-out: ${e.runtimeType}');
    }
  }
}

/// Handles Firebase Cloud Messaging registration and message routing.
/// Android and iOS only; web builds have no push (in-app list only).
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  String? _lastToken;

  Future<void> init() async {
    if (kIsWeb) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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

    // ── Save this device's token (never logged: it addresses this phone) ──
    final token = await _messaging.getToken();
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
      Logger.i('FCM token refreshed');
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
      Logger.i('Notification tapped (background)');
      _routeFromPayload(message.data);
    });

    // ── App opened from a terminated state ──
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Logger.i('App launched via notification');
      _routeFromPayload(initial.data);
    }
  }

  /// Opens the conversation or contract a tapped notification is about
  /// (payload {chatId} or {contractId}, set by the trusted functions). When
  /// the app was just launched, waits briefly for the router.
  void _routeFromPayload(Map<String, dynamic> data, [int attempt = 0]) {
    final route = notificationRouteFor(data, type: data['type']?.toString());
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
      if (user == null) return;
      final previous = _lastToken != null && _lastToken != token ? _lastToken : null;
      await PushTokenStore(FirebaseFirestore.instance).save(user.uid, token, previous: previous);
      _lastToken = token;
      Logger.i('Push token saved for this device');
    } catch (e) {
      Logger.e('Failed to save the push token: $e');
    }
  }
}

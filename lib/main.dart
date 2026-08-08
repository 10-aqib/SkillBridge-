import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/app.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/services/crashlytics_service.dart';
import 'package:skill_bridge/core/services/offline_cache_service.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/firebase_options.dart';
import 'package:skill_bridge/features/notifications/data/services/push_notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // ── Setup Firebase ──
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.i('Firebase initialized successfully');

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
    Logger.i('Firebase App Check initialized');

    // ── Setup non-critical services asynchronously ──
    Future.microtask(() async {
      await CrashlyticsService().init();
      await PushNotificationService().init();
      Logger.i('Crashlytics and Push Notifications initialized');
    });


    // Lock orientation to vertical on mobile devices for baseline UI stability
    // but leave it responsive on web/tablets
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Create a container to initialize Hive synchronously before running the app
    final container = ProviderContainer();
    final hiveService = container.read(hiveServiceProvider);
    await hiveService.init();
    await OfflineCacheService.init();
    Logger.i('Local cache database initialized successfully');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const App(),
      ),
    );
  } catch (error, stackTrace) {
    Logger.e('Critical startup failure', error, stackTrace);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to start Skill Bridge',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

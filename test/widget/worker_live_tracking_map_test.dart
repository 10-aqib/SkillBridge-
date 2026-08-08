import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/worker_live_tracking_map.dart';

void main() {
  group('WorkerLiveTrackingMap Single-Language & Hero Test', () {
    testWidgets(
      'WorkerLiveTrackingMap shows English ONLY and includes Hero tag',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('en', 'US'),
            supportedLocales: [Locale('en', 'US'), Locale('ur', 'PK')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: WorkerLiveTrackingMap(
                workerId: 'worker_999',
                workerName: 'Ustad Tariq',
                workerPhone: '+923001234567',
              ),
            ),
          ),
        );

        expect(find.text('Ustad is en route'), findsOneWidget);
        expect(find.text('استاد راستے میں ہیں'), findsNothing);
        expect(find.text('Call Ustad'), findsOneWidget);
        expect(find.text('کال کریں'), findsNothing);

        final heroFinder = find.byType(Hero);
        expect(heroFinder, findsOneWidget);
        final Hero hero = tester.widget(heroFinder);
        expect(hero.tag, 'worker_avatar_worker_999');
      },
    );

    testWidgets(
      'WorkerLiveTrackingMap shows Urdu ONLY when locale is ur_PK',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('ur', 'PK'),
            supportedLocales: [Locale('en', 'US'), Locale('ur', 'PK')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: WorkerLiveTrackingMap(
                workerId: 'worker_999',
                workerName: 'Ustad Tariq',
                workerPhone: '+923001234567',
              ),
            ),
          ),
        );

        expect(find.text('استاد راستے میں ہیں'), findsOneWidget);
        expect(find.text('Ustad is en route'), findsNothing);
        expect(find.text('کال کریں'), findsOneWidget);
        expect(find.text('Call Ustad'), findsNothing);
      },
    );
  });
}


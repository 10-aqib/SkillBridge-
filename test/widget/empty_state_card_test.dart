import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/shared/widgets/empty_state_card.dart';
import 'package:skill_bridge/shared/widgets/outbox_status_pill.dart';

void main() {
  group('EmptyStateCard & OutboxStatusPill Single-Language Widget Test', () {
    testWidgets(
      'EmptyStateCard displays ONLY English when locale is en_US',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('en', 'US'),
            home: Scaffold(
              body: EmptyStateCard(
                titleEn: 'No jobs posted yet',
                titleUr: 'ابھی کوئی جاب نہیں',
                subtitleEn: 'Tap the plus icon to post',
                subtitleUr: 'جاب پوسٹ کرنے کے لیے پلس پر کلک کریں',
              ),
            ),
          ),
        );

        expect(find.text('No jobs posted yet'), findsOneWidget);
        expect(find.text('ابھی کوئی جاب نہیں'), findsNothing);
      },
    );

    testWidgets('OutboxStatusPill is hidden when pendingCount is 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OutboxStatusPill(pendingCount: 0)),
        ),
      );

      expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
    });

    testWidgets(
      'OutboxStatusPill displays pending action count when > 0',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: OutboxStatusPill(pendingCount: 3)),
          ),
        );

        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
        expect(
          find.text('Offline Mode: 3 pending actions queued'),
          findsOneWidget,
        );
      },
    );
  });
}

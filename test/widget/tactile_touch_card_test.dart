import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/shared/widgets/tactile_touch_card.dart';

void main() {
  group('TactileTouchCard Widget Test', () {
    testWidgets('TactileTouchCard invokes onTap callback when tapped', (
      tester,
    ) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TactileTouchCard(
                onTap: () {
                  wasTapped = true;
                },
                child: const SizedBox(
                  width: 150,
                  height: 60,
                  child: Text('Press Me'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);

      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });
  });
}

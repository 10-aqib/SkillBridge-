import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/shared/widgets/shimmer_loading_card.dart';

void main() {
  group('ShimmerLoadingCard & Skeletons Widget Test', () {
    testWidgets('ShimmerLoadingCard renders and animates cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShimmerLoadingCard(height: 100, width: 200),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoadingCard), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('ShimmerJobCardSkeleton renders without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: ShimmerJobCardSkeleton(),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerJobCardSkeleton), findsOneWidget);
    });

    testWidgets('ShimmerWorkerCardSkeleton renders without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: ShimmerWorkerCardSkeleton(),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerWorkerCardSkeleton), findsOneWidget);
    });
  });
}

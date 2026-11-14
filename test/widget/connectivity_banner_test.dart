import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/shared/widgets/connectivity_banner.dart';

void main() {
  testWidgets('ConnectivityBanner transition from online to offline', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 84);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    final streamController = StreamController<bool>.broadcast();
    addTearDown(streamController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => streamController.stream),
          pendingOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(
              child: Center(child: Text('Home Screen')),
            ),
          ),
        ),
      ),
    );

    // Initial state: connected
    streamController.add(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('No internet connection'), findsNothing);

    // Now go offline!
    streamController.add(false);
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 50)); // Mid-animation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.textContaining('No internet connection'), findsOneWidget);
  });
}

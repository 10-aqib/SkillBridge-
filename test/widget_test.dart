import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen displays SkillBridge title and subtitle', (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Verify title and subtitle rendering on SplashScreen
    expect(find.text('SkillBridge'), findsOneWidget);
    expect(find.text('Local Skills Marketplace'), findsOneWidget);

    // Advance timer past splash screen navigation delay (3s)
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}

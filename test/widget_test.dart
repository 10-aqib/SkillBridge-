import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/auth/presentation/screens/splash_screen.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('SplashScreen shows the SkillBridge brand and tagline, then continues', (
    WidgetTester tester,
  ) async {
    final l = await englishStrings();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: RouteNames.welcomePath, builder: (context, state) => const Text('WELCOME')),
      ],
    );

    await tester.pumpWidget(testRouterApp(router: router));
    await tester.pump();

    expect(find.text('SkillBridge'), findsOneWidget);
    expect(find.text(l.appTagline), findsOneWidget);

    // Signed-out flow continues to Welcome after the brief brand moment.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('WELCOME'), findsOneWidget);
  });
}

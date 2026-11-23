// Brand mark, startup intro, privacy policy screen and the client side menu.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/features/client/presentation/widgets/home_drawer.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/screens/privacy_policy_screen.dart';
import 'package:skill_bridge/shared/widgets/brand/sb_logo.dart';
import 'package:skill_bridge/shared/widgets/brand/startup_intro.dart';

import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  group('Brand mark', () {
    testWidgets('the mark is the SkillBridge logo image (the app icon), labelled SkillBridge', (tester) async {
      await tester.pumpWidget(testApp(home: const Scaffold(body: Center(child: SbBrandMark(size: 64)))));
      expect(find.byType(SbLogoMark), findsOneWidget);
      expect(find.byType(FlutterLogo), findsNothing, reason: 'the Flutter logo is gone');
      final img = tester.widget<Image>(find.descendant(of: find.byType(SbLogoMark), matching: find.byType(Image)));
      expect((img.image as AssetImage).assetName, SbBrandAssets.mark);
      expect(find.bySemanticsLabel('SkillBridge'), findsOneWidget);
    });

    testWidgets('the full logo sits on white in dark mode (navy lettering stays readable)', (tester) async {
      await tester.pumpWidget(testApp(brightness: Brightness.dark, home: const Scaffold(body: Center(child: SbFullLogo()))));
      final box = tester.widget<Container>(find.descendant(of: find.byType(SbFullLogo), matching: find.byType(Container)));
      expect((box.decoration as BoxDecoration).color, Colors.white);
    });

    test('one icon everywhere: generated from the official logo, nothing else left', () {
      final res = Directory('android/app/src/main/res');
      expect(File('tool/brand/skillbridge_logo_source.png').existsSync(), isTrue);
      for (final a in [SbBrandAssets.mark, SbBrandAssets.logo]) {
        expect(File(a).existsSync(), isTrue, reason: a);
      }
      final adaptive = File('${res.path}/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
      expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
      expect(adaptive, contains('<monochrome'));
      expect(File('android/app/src/main/AndroidManifest.xml').readAsStringSync(), contains('@mipmap/ic_launcher'));
      for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        for (final f in ['mipmap-$d/ic_launcher.png', 'mipmap-$d/ic_launcher_foreground.png', 'drawable-$d/launch_logo.png', 'drawable-$d/splash_icon.png']) {
          expect(File('${res.path}/$f').existsSync(), isTrue, reason: f);
        }
        expect(File('${res.path}/mipmap-$d/ic_launcher_round.png').existsSync(), isFalse, reason: d);
      }
      expect(File('${res.path}/drawable/ic_launcher_foreground.xml').existsSync(), isFalse, reason: 'old bridge icon');
      expect(File('${res.path}/values-v31/styles.xml').readAsStringSync(), contains('@drawable/splash_icon'));
    });
  });

  group('Startup intro', () {
    Widget app({bool reduce = false, bool enabled = true}) => testApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
              child: StartupIntro(enabled: enabled, child: const Scaffold(body: Text('APP'))),
            ),
          ),
        );

    testWidgets('"Skill" and "Bridge" slide in, meet, then the intro fades and the app is usable', (tester) async {
      await tester.pumpWidget(app());
      expect(find.text('Skill'), findsOneWidget);
      expect(find.text('Bridge'), findsOneWidget);
      // At the start "Skill" is off to the left and "Bridge" off to the right.
      final skill0 = tester.getCenter(find.text('Skill')).dx;
      final bridge0 = tester.getCenter(find.text('Bridge')).dx;
      await tester.pump(const Duration(milliseconds: 900));
      final skill1 = tester.getCenter(find.text('Skill')).dx;
      final bridge1 = tester.getCenter(find.text('Bridge')).dx;
      expect(skill1, greaterThan(skill0));
      expect(bridge1, lessThan(bridge0));
      // They meet: "Bridge" starts right where "Skill" ends (one word).
      expect(tester.getTopRight(find.text('Skill')).dx, closeTo(tester.getTopLeft(find.text('Bridge')).dx, 1));
      expect(find.byType(SbLogoMark), findsOneWidget);

      await tester.pump(StartupIntro.duration);
      await tester.pump();
      expect(find.text('Skill'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('with reduced motion it shows the finished word briefly, without sliding', (tester) async {
      await tester.pumpWidget(app(reduce: true));
      expect(tester.getTopRight(find.text('Skill')).dx, closeTo(tester.getTopLeft(find.text('Bridge')).dx, 1));
      await tester.pump(); // the animation's first tick
      await tester.pump(StartupIntro.reducedMotionDuration + const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('Skill'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('disabled: the app shows at once', (tester) async {
      await tester.pumpWidget(app(enabled: false));
      expect(find.text('Skill'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });
  });

  group('Privacy policy', () {
    testWidgets('shows the version, the summary and expandable sections', (tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(home: const PrivacyPolicyScreen()));
      expect(find.textContaining(kPrivacyPolicyVersion), findsOneWidget);
      expect(find.text('At a glance'), findsOneWidget);
      expect(find.textContaining('We never collect or store fingerprints'), findsOneWidget);
      expect(find.text('1. Who we are'), findsOneWidget);

      await tester.ensureVisible(find.text('10. Deleting your account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10. Deleting your account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Settings → Account → Delete account'), findsOneWidget);
    });

    test('the in-app policy and PRIVACY_POLICY.md carry the same version', () {
      expect(File('PRIVACY_POLICY.md').readAsStringSync(), contains('| Version | $kPrivacyPolicyVersion'));
    });
  });

  group('Client side menu', () {
    Future<GoRouter> pump(WidgetTester tester, {UserEntity? user}) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => Scaffold(
            drawer: const HomeDrawer(),
            body: Builder(
              builder: (c) => TextButton(onPressed: () => Scaffold.of(c).openDrawer(), child: const Text('OPEN')),
            ),
          ),
        ),
        for (final p in [
          RouteNames.privacyPolicyPath,
          RouteNames.termsAndConditionsPath,
          RouteNames.clientContractsPath,
          RouteNames.clientJobsPath,
          RouteNames.clientPostJobPath,
          RouteNames.identityPath,
          RouteNames.clientSettingsPath,
          RouteNames.clientProfilePath,
          RouteNames.loginPath,
          RouteNames.signupPath,
        ])
          GoRoute(path: p, builder: (_, _) => Text('PAGE $p')),
      ]);
      await tester.pumpWidget(testRouterApp(router: router, overrides: [
        currentUserProvider.overrideWith((ref) => user),
      ]));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('signed-in client: work, account, appearance, help & legal; no "Join as a Professional"', (tester) async {
      await pump(tester, user: testUser('c1'));
      for (final s in [
        l.drawerPostJob, l.drawerMyJobs, l.drawerContracts, l.drawerMessages, l.drawerNotifications,
        l.drawerNearbyWorkers, l.drawerProfile, l.drawerVerifyIdentity, l.drawerSettings, l.customerSupport,
        l.privacyPolicy, l.termsAndConditions, l.drawerAbout, l.drawerShare, l.drawerSignOut,
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.textContaining('Join as a Professional'), findsNothing);
      expect(find.textContaining('Earn'), findsNothing);
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.textContaining('1.2.0'), findsOneWidget);
    });

    testWidgets('Privacy policy and Contracts open their pages and close the menu', (tester) async {
      await pump(tester, user: testUser('c1'));
      await tester.tap(find.text(l.privacyPolicy));
      await tester.pumpAndSettle();
      expect(find.text('PAGE ${RouteNames.privacyPolicyPath}'), findsOneWidget);
    });

    testWidgets('About shows the logo, description and version', (tester) async {
      await pump(tester, user: testUser('c1'));
      await tester.tap(find.text(l.drawerAbout));
      await tester.pumpAndSettle();
      expect(find.text(l.drawerAboutBody), findsOneWidget);
      expect(find.byType(SbLogoMark), findsWidgets);
    });

    testWidgets('signed out: sign in and create account instead of work and account items', (tester) async {
      await pump(tester);
      expect(find.text(l.drawerSignIn), findsOneWidget);
      expect(find.text(l.drawerCreateAccount), findsOneWidget);
      expect(find.text(l.drawerMyJobs), findsNothing);
      expect(find.text(l.drawerSignOut), findsNothing);
      expect(find.text(l.privacyPolicy), findsOneWidget);
    });
  });
}

// "Get verified" (CNIC + NADRA fingerprint), the Verified badge, and the
// one-time "You're verified!" pop-up. Firebase is not used: the signed-in
// person, their CNIC submission and the NADRA availability are overridden.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/app_router.dart' show navigatorKey;
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/identity/data/identity_verification_service.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/features/identity/presentation/get_verified_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verified_badge.dart';
import 'package:skill_bridge/features/worker/data/verification_service.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/test_app.dart';
import 'package:skill_bridge/config/theme/sb/sb_theme.dart';

UserModel _client({bool cnicApproved = false, Map<String, dynamic>? iv}) => UserModel(
      uid: 'c1', email: 'c1@example.com', displayName: 'Ayesha Khan', phoneNumber: '+923001234567', role: 'client',
      isEmailVerified: true, isPhoneVerified: true, isActive: true, isCnicVerified: cnicApproved, identityVerification: iv,
      onboardingCompleted: true, createdAt: DateTime(2026), updatedAt: DateTime(2026),
    );

class _Me extends Notifier<UserEntity?> {
  @override
  UserEntity? build() => _client();
  void set(UserEntity? u) => state = u;
}

const _noNadra = IdentityConfig(provider: null, test: false, consentVersion: '2026-11-22.v1', maxAttempts: 3);

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  Future<void> openHub(WidgetTester tester, UserModel user, {VerificationSubmission? submission}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const GetVerifiedScreen()),
      GoRoute(path: RouteNames.cnicVerificationPath, builder: (_, _) => const Text('CNIC FORM')),
      GoRoute(path: RouteNames.identityPath, builder: (_, _) => const Text('NADRA')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      currentUserProvider.overrideWith((ref) => user),
      verificationSubmissionProvider(user.uid).overrideWith((ref) => Stream.value(submission)),
      identityConfigProvider.overrideWith((ref) async => _noNadra),
    ]));
    await tester.pumpAndSettle();
  }

  testWidgets('not verified yet: start with the CNIC; fingerprint says "Coming soon" and collects nothing', (tester) async {
    await openHub(tester, _client());
    expect(find.text(l.getVerifiedHeaderTitle), findsOneWidget);
    expect(find.text(l.getVerifiedStepCnic), findsOneWidget);
    expect(find.text(l.getVerifiedStatusNotStarted), findsOneWidget);
    expect(find.text(l.getVerifiedComingSoon), findsOneWidget);
    expect(find.text(l.getVerifiedFingerprintSoon), findsOneWidget);
    expect(find.text(l.getVerifiedStart), findsOneWidget, reason: 'only the CNIC step can start');
    expect(find.byType(VerifiedPill), findsNothing);

    await tester.tap(find.text(l.getVerifiedStart));
    await tester.pumpAndSettle();
    expect(find.text('CNIC FORM'), findsOneWidget);
  });

  testWidgets('CNIC sent: "Under review"', (tester) async {
    await openHub(tester, _client(), submission: const VerificationSubmission(status: 'pending', documentCount: 2));
    expect(find.text(l.getVerifiedStatusReview), findsOneWidget);
    expect(find.text(l.getVerifiedView), findsOneWidget);
  });

  testWidgets('CNIC approved by staff: verified, with the badge', (tester) async {
    await openHub(tester, _client(cnicApproved: true));
    expect(find.text(l.getVerifiedDoneTitle), findsOneWidget);
    expect(find.text(l.getVerifiedStatusDone), findsOneWidget);
    expect(find.byType(VerifiedPill), findsOneWidget);
  });

  test('who gets the Verified badge', () {
    expect(isIdentityVerified(_client()), isFalse);
    expect(isIdentityVerified(_client(cnicApproved: true)), isTrue);
    expect(isIdentityVerified(_client(iv: {'status': 'verified', 'verified': true, 'provider': 'nadra', 'test': false})), isTrue);
    // A simulated (test) result is never a real verification.
    expect(isIdentityVerified(_client(iv: {'status': 'verified', 'verified': true, 'provider': 'simulator', 'test': true})), isFalse);
    expect(isIdentityVerified(null), isFalse);
  });

  testWidgets('the badge shows only for verified people', (tester) async {
    await tester.pumpWidget(testApp(home: Scaffold(body: Column(children: [VerifiedBadge(user: _client()), VerifiedBadge(user: _client(cnicApproved: true))]))));
    expect(find.byType(VerifiedPill), findsOneWidget);
    expect(find.text(l.verifiedBadge), findsOneWidget);
  });

  testWidgets('"You\'re verified!" pops up once, when the person becomes verified', (tester) async {
    final user = NotifierProvider<_Me, UserEntity?>(_Me.new);
    late WidgetRef outer;
    await tester.pumpWidget(ProviderScope(
      overrides: [currentUserProvider.overrideWith((ref) => ref.watch(user))],
      child: Consumer(builder: (context, ref, _) {
        outer = ref;
        return MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: testLocalizations,
          supportedLocales: const [Locale('en')],
          theme: SbTheme.light(useGoogleFonts: false),
          builder: (context, child) => VerifiedCelebrationWatcher(startDelay: Duration.zero, child: child!),
          home: const Scaffold(body: Text('HOME')),
        );
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text(l.verifiedPopupTitle), findsNothing, reason: 'not verified yet');

    outer.read(user.notifier).set(_client(cnicApproved: true));
    await tester.pumpAndSettle();
    expect(find.text(l.verifiedPopupTitle), findsOneWidget);
    expect(find.byType(VerifiedPill), findsOneWidget);

    await tester.tap(find.text(l.verifiedPopupOk));
    await tester.pumpAndSettle();
    expect(find.text(l.verifiedPopupTitle), findsNothing);

    // A later profile update doesn't repeat it.
    outer.read(user.notifier).set(_client(cnicApproved: true).copyWith(displayName: 'Ayesha K.'));
    await tester.pumpAndSettle();
    expect(find.text(l.verifiedPopupTitle), findsNothing);
  });
}

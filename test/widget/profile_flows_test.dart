// Client onboarding, settings sign-out, the email-verification card and the
// worker verification screen. All Firebase access is mocked (fake repository,
// overridden providers) — these are not Firebase integration tests. The
// security rules behind these screens are tested against the emulator in
// rules-tests/.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/screens/client_onboarding_screen.dart';
import 'package:skill_bridge/features/worker/data/verification_service.dart';
import 'package:skill_bridge/features/worker/presentation/screens/verification_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/shared/widgets/profile/settings_view.dart';

import '../helpers/test_app.dart';

class FakeAuthRepository implements AuthRepository {
  final updates = <Map<String, dynamic>>[];
  int signOuts = 0;
  int verificationEmails = 0;
  bool emailVerifiedOnServer = false;
  bool failUpdates = false;

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({required String uid, required Map<String, dynamic> data}) async {
    if (failUpdates) return const Left(ServerFailure('PERMISSION_DENIED'));
    updates.add(data);
    return Right(_user(uid));
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    signOuts++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    verificationEmails++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> refreshEmailVerification() async => Right(emailVerifiedOnServer);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirestore extends Mock implements FirebaseFirestore {}

class RecordingVerificationService extends VerificationService {
  RecordingVerificationService() : super(MockFirestore());
  final submissions = <List<String>>[];

  @override
  Future<void> submit({required String uid, required String cnic, required List<String> documentPaths}) async {
    submissions.add(documentPaths);
  }
}

UserModel _user(
  String uid, {
  String role = 'client',
  String phone = '',
  bool emailVerified = true,
  String? cnic,
  WorkerProfileEntity? worker,
}) =>
    UserModel(
      uid: uid,
      email: '$uid@example.com',
      displayName: 'Ayesha Khan',
      phoneNumber: phone,
      role: role,
      isEmailVerified: emailVerified,
      isPhoneVerified: false,
      isActive: true,
      cnicNumber: cnic,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      workerProfile: worker,
    );

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  late FakeAuthRepository repo;
  setUp(() => repo = FakeAuthRepository());

  GoRouter routerFor(Widget screen) => GoRouter(initialLocation: '/start', routes: [
        GoRoute(
          path: '/start',
          builder: (_, _) => Builder(
            builder: (c) => TextButton(onPressed: () => c.push('/screen'), child: const Text('open')),
          ),
        ),
        GoRoute(path: '/screen', builder: (_, _) => screen),
        GoRoute(path: RouteNames.clientHomePath, builder: (_, _) => const Text('CLIENT HOME')),
        GoRoute(path: RouteNames.welcomePath, builder: (_, _) => const Text('WELCOME')),
      ]);

  Future<void> pumpScreen(WidgetTester tester, Widget screen, UserEntity user, {List<dynamic> extra = const []}) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testRouterApp(router: routerFor(screen), overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith((ref) => user),
      ...extra,
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('Client onboarding', () {
    testWidgets('finishing saves only what was entered and marks onboarding done', (tester) async {
      await pumpScreen(tester, const ClientOnboardingScreen(), _user('c1'));
      expect(find.text(l.clientOnboardingYouTitle), findsOneWidget);
      await tester.tap(find.text(l.continueText));
      await tester.pumpAndSettle();

      expect(find.text(l.clientOnboardingContactTitle), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '3001234567');
      await tester.tap(find.text(l.continueText));
      await tester.pumpAndSettle();

      expect(find.text(l.clientOnboardingLocationTitle), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karachi').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.onboardingFinish));
      await tester.pumpAndSettle();

      expect(repo.updates.single, {
        'onboardingCompleted': true,
        'displayName': 'Ayesha Khan',
        'phoneNumber': '+923001234567',
        'city': 'Karachi',
      });
      expect(find.text('CLIENT HOME'), findsOneWidget);
    });

    testWidgets('an invalid phone number blocks the step', (tester) async {
      await pumpScreen(tester, const ClientOnboardingScreen(), _user('c1'));
      await tester.tap(find.text(l.continueText));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.text(l.continueText));
      await tester.pumpAndSettle();
      expect(find.text(l.clientOnboardingContactTitle), findsOneWidget);
      expect(repo.updates, isEmpty);
    });

    testWidgets('skip saves nothing but the completed flag', (tester) async {
      await pumpScreen(tester, const ClientOnboardingScreen(), _user('c1'));
      await tester.tap(find.text(l.onboardingSkip));
      await tester.pumpAndSettle();
      expect(repo.updates.single, {'onboardingCompleted': true});
      expect(find.text('CLIENT HOME'), findsOneWidget);
    });

    testWidgets('a failed save stays on the screen with an error', (tester) async {
      repo.failUpdates = true;
      await pumpScreen(tester, const ClientOnboardingScreen(), _user('c1'));
      await tester.tap(find.text(l.onboardingSkip));
      await tester.pumpAndSettle();
      expect(find.text(l.profileSaveFailed), findsOneWidget);
      expect(find.text('CLIENT HOME'), findsNothing);
    });
  });

  group('Settings sign-out', () {
    testWidgets('cancel keeps the user signed in', (tester) async {
      await pumpScreen(tester, const SettingsView(), _user('c1'));
      await tester.tap(find.text(l.signOut));
      await tester.pumpAndSettle();
      expect(find.text(l.signOutConfirmTitle), findsOneWidget);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(repo.signOuts, 0);
      expect(find.text('WELCOME'), findsNothing);
    });

    testWidgets('confirm signs out and returns to Welcome', (tester) async {
      await pumpScreen(tester, const SettingsView(), _user('c1'));
      await tester.tap(find.text(l.signOut));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.signOut).last);
      await tester.pumpAndSettle();
      expect(repo.signOuts, 1);
      expect(find.text('WELCOME'), findsOneWidget);
    });
  });

  group('Email verification card', () {
    Widget card(UserEntity u) => Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: EmailVerificationCard(user: u)));

    testWidgets('hidden once the email is verified', (tester) async {
      await pumpScreen(tester, card(_user('c1')), _user('c1'));
      expect(find.text(l.verifyEmailTitle), findsNothing);
    });

    testWidgets('after a "not verified yet" check, resending confirms the new email', (tester) async {
      final u = _user('c1', emailVerified: false);
      await pumpScreen(tester, card(u), u);
      await tester.tap(find.text(l.verifyEmailCheck));
      await tester.pumpAndSettle();
      expect(find.text(l.verifyEmailStillPending), findsOneWidget);

      await tester.tap(find.text(l.verifyEmailResend));
      await tester.pumpAndSettle();
      expect(repo.verificationEmails, 1);
      expect(find.text(l.verifyEmailSent), findsOneWidget);
      expect(find.text(l.verifyEmailStillPending), findsNothing);
    });

    testWidgets('resend sends once and disables; check reports still pending', (tester) async {
      final u = _user('c1', emailVerified: false);
      await pumpScreen(tester, card(u), u);
      expect(find.text(l.verifyEmailTitle), findsOneWidget);

      await tester.tap(find.text(l.verifyEmailResend));
      await tester.pumpAndSettle();
      expect(repo.verificationEmails, 1);
      expect(find.text(l.verifyEmailSent), findsOneWidget);
      await tester.tap(find.text(l.verifyEmailResend));
      await tester.pumpAndSettle();
      expect(repo.verificationEmails, 1, reason: 'disabled after sending');

      await tester.tap(find.text(l.verifyEmailCheck));
      await tester.pumpAndSettle();
      expect(find.text(l.verifyEmailStillPending), findsOneWidget);
    });
  });

  group('Worker verification screen', () {
    const profile = WorkerProfileEntity(
        headline: 'Plumber', bio: 'Leak repairs and fittings.', categoryId: 'plumber', categoryName: 'Plumber', city: 'Lahore');

    List<dynamic> overrides(String uid, VerificationSubmission? sub, RecordingVerificationService svc) => [
          verificationSubmissionProvider(uid).overrideWith((ref) => Stream.value(sub)),
          verificationServiceProvider.overrideWithValue(svc),
        ];

    testWidgets('not submitted: validation blocks submit until CNIC, front, back and consent are given', (tester) async {
      final svc = RecordingVerificationService();
      final u = _user('w1', role: 'worker', worker: profile);
      await pumpScreen(tester, const VerificationScreen(), u, extra: overrides('w1', null, svc));

      expect(find.text(l.verificationIntroTitle), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '3520212');
      await tester.tap(find.text(l.verificationSubmit));
      await tester.pumpAndSettle();

      expect(find.text(l.verificationCnicInvalid), findsOneWidget);
      expect(find.text(l.verificationDocMissing), findsNWidgets(2), reason: 'front and back required; extra optional');
      expect(find.text(l.verificationConsentRequired), findsOneWidget);
      expect(svc.submissions, isEmpty);
    });

    testWidgets('pending submission shows only masked details, never the full CNIC', (tester) async {
      final u = _user('w1', role: 'worker', worker: profile);
      final sub = VerificationSubmission(
        status: 'pending',
        documentCount: 2,
        maskedCnic: VerificationSubmission.mask('35202-1234567-1'),
        submittedAt: DateTime(2026, 3, 4),
      );
      await pumpScreen(tester, const VerificationScreen(), u, extra: overrides('w1', sub, RecordingVerificationService()));
      expect(find.text(l.verificationPendingTitle), findsOneWidget);
      expect(find.text(l.verificationCnicOnFile('35202-•••••••-1')), findsOneWidget);
      expect(find.textContaining('1234567'), findsNothing);
      expect(find.text(l.verificationVerifiedTitle), findsNothing);
      expect(find.text(l.verificationUpdate), findsOneWidget);
    });

    testWidgets('verified only when staff set workerProfile.isVerified', (tester) async {
      final u = _user('w1', role: 'worker', worker: const WorkerProfileEntity(
          headline: 'Plumber', bio: 'Leak repairs.', categoryId: 'plumber', categoryName: 'Plumber', city: 'Lahore',
          isVerified: true, verificationStatus: 'verified'));
      await pumpScreen(tester, const VerificationScreen(), u, extra: overrides('w1', null, RecordingVerificationService()));
      expect(find.text(l.verificationVerifiedTitle), findsOneWidget);
      expect(find.text(l.verificationSubmit), findsNothing);
    });

    testWidgets('rejected submission shows the form again', (tester) async {
      final u = _user('w1', role: 'worker', worker: profile);
      const sub = VerificationSubmission(status: 'rejected', documentCount: 2);
      await pumpScreen(tester, const VerificationScreen(), u, extra: overrides('w1', sub, RecordingVerificationService()));
      expect(find.text(l.verificationRejectedTitle), findsOneWidget);
      expect(find.text(l.verificationSubmit), findsOneWidget);
    });

    testWidgets('a legacy public CNIC is removed only after the owner confirms', (tester) async {
      final u = _user('w1', role: 'worker', cnic: '35202-1234567-1', worker: profile);
      await pumpScreen(tester, const VerificationScreen(), u, extra: overrides('w1', null, RecordingVerificationService()));
      expect(find.text(l.verificationLegacyNotice), findsOneWidget);

      await tester.tap(find.text(l.verificationLegacyRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.cancel).last);
      await tester.pumpAndSettle();
      expect(repo.updates, isEmpty);

      await tester.tap(find.text(l.verificationLegacyRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.verificationLegacyRemove).last);
      await tester.pumpAndSettle();
      expect(repo.updates.single['cnicNumber'], FieldValue.delete());
      expect(repo.updates.single.length, 1, reason: 'nothing else touched');
      expect(find.text(l.verificationLegacyRemoved), findsOneWidget);
    });
  });

  group('Verification & media helpers', () {
    test('CNIC formatter inserts dashes and caps at 13 digits', () {
      final f = CnicInputFormatter();
      String fmt(String s) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s)).text;
      expect(fmt('3520212345671'), '35202-1234567-1');
      expect(fmt('35202'), '35202');
      expect(fmt('352021'), '35202-1');
      expect(fmt('35202-12ab34567-19999'), '35202-1234567-1');
    });

    test('CNIC pattern and mask', () {
      expect(VerificationService.cnicPattern.hasMatch('35202-1234567-1'), isTrue);
      expect(VerificationService.cnicPattern.hasMatch('3520212345671'), isFalse);
      expect(VerificationSubmission.mask('35202-1234567-1'), '35202-•••••••-1');
      expect(VerificationSubmission.mask('bad'), isNull);
    });

    test('submit rejects a malformed CNIC or document count before writing anything', () async {
      final firestore = MockFirestore();
      final svc = VerificationService(firestore);
      await expectLater(svc.submit(uid: 'u', cnic: '123', documentPaths: ['a']), throwsArgumentError);
      await expectLater(svc.submit(uid: 'u', cnic: '35202-1234567-1', documentPaths: const []), throwsArgumentError);
      await expectLater(svc.submit(uid: 'u', cnic: '35202-1234567-1', documentPaths: ['a', 'b', 'c', 'd']), throwsArgumentError);
      verifyZeroInteractions(firestore);
    });

    test('upload content types: images always, PDF only where allowed', () {
      expect(ProfileMediaService.contentTypeFor('photo.JPG'), 'image/jpeg');
      expect(ProfileMediaService.contentTypeFor('x.png'), 'image/png');
      expect(ProfileMediaService.contentTypeFor('x', mimeType: 'image/webp'), 'image/webp');
      expect(ProfileMediaService.contentTypeFor('doc.pdf'), isNull);
      expect(ProfileMediaService.contentTypeFor('doc.pdf', allowPdf: true), 'application/pdf');
      expect(ProfileMediaService.contentTypeFor('evil.exe'), isNull);
      expect(ProfileMediaService.contentTypeFor('x.svg', mimeType: 'text/html'), isNull);
      expect(ProfileMediaService.maxBytes, 2 * 1024 * 1024, reason: 'matches the image host upload preset (free plan, Phase S6)');
    });
  });
}

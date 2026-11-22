import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/identity/data/biometric_capture_service.dart';
import 'package:skill_bridge/features/identity/data/identity_verification_service.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/features/identity/presentation/identity_verification_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verification_status_widget.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

// NADRA track: identity verification UI against a fake server. Only the
// test simulator path can run; the real NADRA path reports "not available".

class _Server extends IdentityVerificationService {
  _Server({required this.cfg, this.results = const []}) : super(() => throw StateError('unused'));
  final IdentityConfig cfg;
  final List<IdentitySubmitResult> results;
  final calls = <String>[];
  IdentityProblem? startProblem;

  @override
  Future<IdentityConfig> config() async => cfg;

  @override
  Future<IdentitySession> start({required String cnic, required String consentVersion}) async {
    calls.add('start:$cnic:$consentVersion');
    if (startProblem != null) throw IdentityException(startProblem!);
    return IdentitySession(sessionId: 'session0001', provider: cfg.provider ?? '', test: cfg.test, expiresAt: DateTime.now().add(const Duration(minutes: 15)));
  }

  @override
  Future<IdentitySubmitResult> submit({required String sessionId, required String cnic, required String requestId, required Map<String, Object?> capture}) async {
    calls.add('submit:$cnic:${capture['format']}');
    return results[calls.where((c) => c.startsWith('submit')).length - 1];
  }

  @override
  Future<void> cancel(String sessionId) async => calls.add('cancel:$sessionId');
}

UserModel _user({Map<String, dynamic>? iv, bool cnic = false}) => UserModel(
      uid: 'a', email: 'a@example.com', displayName: 'A', phoneNumber: '', role: 'worker',
      isEmailVerified: true, isPhoneVerified: false, isActive: true, isCnicVerified: cnic, identityVerification: iv,
      createdAt: DateTime(2026), updatedAt: DateTime(2026),
    );

const _testConfig = IdentityConfig(provider: 'simulator', test: true, consentVersion: '2026-11-22.v1', maxAttempts: 3);

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  Future<_Server> open(WidgetTester tester, _Server server, {UserModel? user, SimulatedScenario scenario = SimulatedScenario.goodCapture}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const IdentityVerificationScreen()),
      GoRoute(path: '/identity/history', builder: (_, _) => const Text('HISTORY')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      currentUserProvider.overrideWith((ref) => user ?? testUser('w1', role: 'worker')),
      identityVerificationServiceProvider.overrideWithValue(server),
      identityConfigProvider.overrideWith((ref) async => server.cfg),
      biometricCaptureServiceProvider('simulator')
          .overrideWithValue(SimulatedCaptureService(scenario: scenario, step: const Duration(milliseconds: 10))),
    ]));
    await tester.pumpAndSettle();
    return server;
  }

  Future<void> enterCnicAndConsent(WidgetTester tester, String cnic) async {
    await tester.tap(find.text(l.identityStart));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), cnic);
    await tester.tap(find.text(l.identityContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text(l.consentAgree));
    await tester.pumpAndSettle();
  }

  Future<void> scanAndSubmit(WidgetTester tester) async {
    await tester.tap(find.text(l.captureStart));
    await tester.pumpAndSettle();
    expect(find.text(l.captureSuccess), findsOneWidget, reason: 'captured is not the same as verified');
    await tester.tap(find.text(l.captureSubmit));
    await tester.pumpAndSettle();
  }

  group('availability', () {
    testWidgets('no authorised NADRA access: explained, nothing can be started, nothing collected', (tester) async {
      final server = await open(tester, _Server(cfg: IdentityConfig.unavailable));
      expect(find.textContaining(l.identityNotAvailableTitle), findsOneWidget);
      expect(find.text(l.identityStart), findsNothing);
      expect(server.calls, isEmpty);
    });

    testWidgets('test environment: TEST banner before anything starts', (tester) async {
      await open(tester, _Server(cfg: _testConfig));
      expect(find.text(l.identityTestBanner), findsOneWidget);
      expect(find.text(l.identityStart), findsOneWidget);
    });
  });

  group('flows (test simulator)', () {
    testWidgets('worker: CNIC → consent → scan → check → TEST result; never a NADRA badge', (tester) async {
      final server = await open(tester, _Server(cfg: _testConfig, results: const [
        IdentitySubmitResult(status: IdentityStatus.verified, test: true),
      ]));
      await enterCnicAndConsent(tester, '9999900000011');
      expect(server.calls.first, 'start:99999-0000001-1:2026-11-22.v1');
      await scanAndSubmit(tester);
      expect(server.calls.last, 'submit:99999-0000001-1:simulated');
      expect(find.text(l.resultTestTitle), findsOneWidget);
      expect(find.text(l.resultVerifiedTitle), findsNothing);
      expect(find.text(l.identityTestBanner), findsOneWidget);
    });

    testWidgets('hirer: the same flow and model', (tester) async {
      final server = await open(tester, _Server(cfg: _testConfig, results: const [
        IdentitySubmitResult(status: IdentityStatus.verified, test: true),
      ]), user: testUser('c1', role: 'client'));
      await enterCnicAndConsent(tester, '99999-0000001-1');
      await scanAndSubmit(tester);
      expect(find.text(l.resultTestTitle), findsOneWidget);
      expect(server.calls.length, 2);
    });

    testWidgets('invalid CNIC is refused before anything is sent', (tester) async {
      final server = await open(tester, _Server(cfg: _testConfig));
      await tester.tap(find.text(l.identityStart));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12345');
      await tester.tap(find.text(l.identityContinue));
      await tester.pump();
      expect(find.text(l.cnicInvalid), findsOneWidget);
      expect(server.calls, isEmpty);
    });

    testWidgets('consent: the button stays off until the box is ticked; cancelling sends nothing', (tester) async {
      final server = await open(tester, _Server(cfg: _testConfig));
      await tester.tap(find.text(l.identityStart));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '9999900000011');
      await tester.tap(find.text(l.identityContinue));
      await tester.pumpAndSettle();
      final agree = tester.widget<ButtonStyleButton>(find.ancestor(of: find.text(l.consentAgree), matching: find.bySubtype<ButtonStyleButton>()).first);
      expect(agree.onPressed, isNull);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(server.calls, isEmpty);
    });

    testWidgets('scanner unplugged, finger not detected, capture failure: explained, nothing submitted', (tester) async {
      for (final (scenario, text) in [
        (SimulatedScenario.scannerDisconnected, l.captureDisconnected),
        (SimulatedScenario.fingerNotDetected, l.captureNotDetected),
        (SimulatedScenario.captureFails, l.captureFailed),
        (SimulatedScenario.poorQuality, l.capturePoorQuality),
      ]) {
        final server = await open(tester, _Server(cfg: _testConfig), scenario: scenario);
        await enterCnicAndConsent(tester, '9999900000011');
        await tester.tap(find.text(l.captureStart));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget, reason: '$scenario');
        expect(find.text(l.captureSubmit), findsNothing);
        expect(server.calls.where((c) => c.startsWith('submit')), isEmpty);
        // Cancel: the session is closed on the server.
        await tester.tap(find.text(l.cancel));
        await tester.pumpAndSettle();
        expect(server.calls.last, 'cancel:session0001');
      }
    });

    testWidgets('a retryable answer offers "try again" in the same session; a mismatch does not', (tester) async {
      final server = await open(tester, _Server(cfg: _testConfig, results: const [
        IdentitySubmitResult(status: IdentityStatus.pending, failureCategory: 'service_unavailable', test: true, attemptsLeft: 2),
        IdentitySubmitResult(status: IdentityStatus.rejected, failureCategory: 'fingerprint_mismatch', test: true),
      ]));
      await enterCnicAndConsent(tester, '9999900000044');
      await scanAndSubmit(tester);
      expect(find.text(l.resultRetryService(2)), findsOneWidget);
      await tester.tap(find.text(l.resultTryAgain));
      await tester.pumpAndSettle();
      await scanAndSubmit(tester);
      expect(find.text(l.resultRejectedTitle), findsOneWidget);
      expect(find.text(l.resultTryAgain), findsNothing);
      expect(server.calls.where((c) => c.startsWith('start')).length, 1, reason: 'one session');
    });

    testWidgets('server refusals are explained (e.g. CNIC already used)', (tester) async {
      final server = _Server(cfg: _testConfig)..startProblem = IdentityProblem.inUse;
      await open(tester, server);
      await enterCnicAndConsent(tester, '9999900000011');
      expect(find.text(l.identityErrInUse), findsOneWidget);
    });
  });

  group('rules of display', () {
    test('only an authentic NADRA result counts as verified; a forged or test map does not', () {
      expect(IdentityState.fromMap({'status': 'verified', 'verified': true, 'provider': 'nadra', 'test': false}).verified, isTrue);
      expect(IdentityState.fromMap({'status': 'verified', 'verified': true, 'provider': 'simulator', 'test': false}).verified, isFalse);
      expect(IdentityState.fromMap({'status': 'verified', 'verified': true, 'provider': 'nadra', 'test': true}).verified, isFalse);
      expect(IdentityState.fromMap({'status': 'pending', 'verified': true, 'provider': 'nadra'}).verified, isFalse);
      expect(IdentityState.fromMap(null).status, IdentityStatus.notStarted);
    });

    test('badges keep their meanings apart', () {
      expect(identityBadgesFor(_user()), isEmpty);
      final real = _user(iv: {'status': 'verified', 'verified': true, 'provider': 'nadra', 'test': false});
      expect(identityBadgesFor(real), [IdentityBadge.nadraVerified]);
      final sim = _user(iv: {'status': 'verified', 'verified': false, 'provider': 'simulator', 'test': true});
      expect(identityBadgesFor(sim), [IdentityBadge.testVerification]);
      final docs = _user(cnic: true);
      expect(identityBadgesFor(docs), [IdentityBadge.documentReviewed]);
    });

    testWidgets('badge labels: NADRA verified / TEST verification / ID documents reviewed', (tester) async {
      final both = _user(cnic: true, iv: {'status': 'verified', 'verified': true, 'provider': 'nadra', 'test': false});
      await tester.pumpWidget(testApp(home: Scaffold(body: IdentityBadges(user: both))));
      expect(find.text(l.identityBadgeNadra), findsOneWidget);
      expect(find.text(l.verificationBadge), findsOneWidget);
      expect(find.text(l.identityBadgeTest), findsNothing);
    });

    test('CNIC: format, mask and the input formatter', () {
      expect(CnicValidation.isValid('35202-1234567-1'), isTrue);
      expect(CnicValidation.isValid('3520212345671'), isTrue);
      expect(CnicValidation.isValid('35202-123456-1'), isFalse);
      expect(CnicValidation.isValid('0520212345671'), isFalse);
      expect(CnicValidation.isValid('1111111111111'), isFalse);
      expect(CnicValidation.mask('3520212345671'), '35202-•••••••-1');
      final f = CnicInputFormatter().formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '35202123456719999'));
      expect(f.text, '35202-1234567-1');
      expect(CnicInputFormatter().formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: 'ab3520')).text, '3520');
    });

    test('server error codes map to clear reasons', () {
      expect(IdentityVerificationService.problemFor('failed-precondition', 'recent-login-required'), IdentityProblem.recentLogin);
      expect(IdentityVerificationService.problemFor('failed-precondition', 'not-available'), IdentityProblem.notAvailable);
      expect(IdentityVerificationService.problemFor('already-exists', 'cnic-in-use'), IdentityProblem.inUse);
      expect(IdentityVerificationService.problemFor('invalid-argument', 'synthetic-cnic-required'), IdentityProblem.syntheticOnly);
      expect(IdentityVerificationService.problemFor('resource-exhausted', 'attempt-limit'), IdentityProblem.attemptLimit);
      expect(IdentityVerificationService.problemFor('deadline-exceeded', 'session-expired'), IdentityProblem.expired);
      expect(IdentityVerificationService.problemFor('not-found', null), IdentityProblem.notAvailable);
    });

    test('without an approved SDK nothing is captured', () async {
      const none = NoApprovedCaptureService();
      expect(await none.availability(), CaptureAvailability.noApprovedSdk);
      expect((await none.capture().toList()).single.result, isNull);
      expect(none.isSimulated, isFalse);
    });

    test('without Firebase, identity verification reports "not available" (no crash)', () async {
      final s = IdentityVerificationService(() => throw StateError('no app'));
      expect((await s.config()).available, isFalse);
    });
  });
}

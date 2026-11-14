import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/otp_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/signup_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/splash_screen.dart';
import 'package:skill_bridge/features/auth/presentation/screens/welcome_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/test_app.dart';

/// In-memory AuthRepository: records calls, returns configured results.
/// Mocked — these tests exercise the UI flows, not real Firebase.
class FakeAuthRepository implements AuthRepository {
  final calls = <String>[];
  Map<String, dynamic>? lastRegister;
  String? lastRole;
  String? lastResetEmail;
  String? lastOtp;
  Either<Failure, UserEntity>? registerResult;
  Either<Failure, UserEntity>? googleResult;
  Either<Failure, UserEntity>? completeResult;
  Either<Failure, void>? resetResult;
  Completer<void>? registerGate;

  final user = UserEntity(
    uid: 'u1', email: 'a@b.com', displayName: 'A', phoneNumber: '', role: 'client',
    isEmailVerified: false, isPhoneVerified: false, isActive: true,
    createdAt: DateTime(2026), updatedAt: DateTime(2026),
  );

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email, required String password, required String displayName,
    required String phoneNumber, required String role, String? city,
  }) async {
    calls.add('register');
    lastRegister = {'email': email, 'password': password, 'name': displayName, 'phone': phoneNumber, 'role': role};
    if (registerGate != null) await registerGate!.future;
    return registerResult ?? Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle({String? role}) async {
    calls.add('google');
    lastRole = role;
    return googleResult ?? Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> completeProfile({required String role, String? displayName, String? phoneNumber}) async {
    calls.add('complete');
    lastRole = role;
    return completeResult ?? Right(user);
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email}) async {
    calls.add('reset');
    lastResetEmail = email;
    return resetResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, String>> sendPhoneOtp({required String phoneNumber}) async {
    calls.add('sendOtp:$phoneNumber');
    return const Right('verification-id');
  }

  @override
  Future<Either<Failure, void>> verifyPhoneOtp({required String verificationId, required String smsCode}) async {
    calls.add('verifyOtp');
    lastOtp = smsCode;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    calls.add('signOut');
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late AppLocalizations l;
  late FakeAuthRepository repo;
  setUpAll(() async => l = await englishStrings());
  setUp(() => repo = FakeAuthRepository());

  GoRouter router(String initial, Widget Function(GoRouterState) screen) => GoRouter(
        initialLocation: initial,
        routes: [
          GoRoute(path: initial.split('?').first, builder: (_, s) => screen(s)),
          for (final p in [
            RouteNames.welcomePath, RouteNames.loginPath, RouteNames.signupPath,
            RouteNames.roleSelectionPath, RouteNames.forgotPasswordPath, RouteNames.termsAndConditionsPath,
          ])
            if (p != initial.split('?').first) GoRoute(path: p, builder: (_, _) => Text('PAGE $p')),
        ],
      );

  Future<void> pump(WidgetTester tester, GoRouter r, {List<dynamic> extra = const [], Size size = const Size(400, 1600)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testRouterApp(
      router: r,
      overrides: [authRepositoryProvider.overrideWithValue(repo), ...extra],
    ));
    await tester.pumpAndSettle();
  }

  group('Splash', () {
    testWidgets('shows the brand and tagline, then continues to Welcome', (tester) async {
      await pump(tester, router(RouteNames.splashPath, (_) => const SplashScreen()));
      expect(find.text('PAGE ${RouteNames.welcomePath}'), findsOneWidget);
    });

    testWidgets('renders the tagline before navigating', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testRouterApp(router: router(RouteNames.splashPath, (_) => const SplashScreen())));
      await tester.pump();
      expect(find.text('SkillBridge'), findsOneWidget);
      expect(find.text(l.appTagline), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('Welcome', () {
    testWidgets('offers create account, Google and sign in', (tester) async {
      await pump(tester, router(RouteNames.welcomePath, (_) => const WelcomeScreen()));
      expect(find.text(l.welcomeTitle), findsOneWidget);
      await tester.tap(find.text(l.welcomeSignIn));
      await tester.pumpAndSettle();
      expect(find.text('PAGE ${RouteNames.loginPath}'), findsOneWidget);
    });

    testWidgets('new Google account goes to role selection', (tester) async {
      repo.googleResult = const Left(AuthFailure('choose', 'needs-role'));
      await pump(tester, router(RouteNames.welcomePath, (_) => const WelcomeScreen()));
      await tester.tap(find.text(l.authContinueWithGoogle));
      await tester.pumpAndSettle();
      expect(repo.lastRole, isNull);
      expect(find.text('PAGE ${RouteNames.roleSelectionPath}'), findsOneWidget);
    });
  });

  group('Sign-up', () {
    Future<void> fill(WidgetTester tester, {String password = 'secret123', String confirm = 'secret123', String phone = '0300 1234567'}) async {
      final f = find.byType(TextFormField);
      await tester.enterText(f.at(0), 'Sana Ahmed');
      await tester.enterText(f.at(1), 'sana@example.com');
      await tester.enterText(f.at(2), phone);
      await tester.enterText(f.at(3), password);
      await tester.enterText(f.at(4), confirm);
    }

    testWidgets('worker link opens the worker variant', (tester) async {
      await pump(tester, router('${RouteNames.signupPath}?role=worker',
          (s) => SignupScreen(initialRole: s.uri.queryParameters['role'])));
      expect(find.text(l.signupTitleWorker), findsOneWidget);
    });

    testWidgets('an unknown role in the link falls back to client', (tester) async {
      await pump(tester, router('${RouteNames.signupPath}?role=admin',
          (s) => SignupScreen(initialRole: s.uri.queryParameters['role'])));
      expect(find.text(l.signupTitleClient), findsOneWidget);
    });

    testWidgets('validates fields and terms before creating an account', (tester) async {
      await pump(tester, router(RouteNames.signupPath, (_) => const SignupScreen()));
      await fill(tester, password: 'short', confirm: 'other', phone: '123');
      await tester.tap(find.text(l.signupButton));
      await tester.pumpAndSettle();
      expect(find.text(l.validationPasswordWeak), findsOneWidget);
      expect(find.text(l.validationPasswordMismatch), findsOneWidget);
      expect(find.text(l.validationPhoneInvalid), findsOneWidget);
      expect(find.text(l.signupAgreeRequired), findsOneWidget);
      expect(repo.calls, isNot(contains('register')));
    });

    testWidgets('registers a worker with a normalised phone, once', (tester) async {
      repo.registerGate = Completer<void>();
      await pump(tester, router(RouteNames.signupPath, (_) => const SignupScreen()));
      await tester.tap(find.text(l.roleWorkerTitle));
      await fill(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text(l.signupButton));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done); // second submit attempt
      await tester.pump();
      expect(repo.calls.where((c) => c == 'register').length, 1);
      expect(repo.lastRegister, {
        'email': 'sana@example.com', 'password': 'secret123', 'name': 'Sana Ahmed',
        'phone': '+923001234567', 'role': UserRoles.worker,
      });
      repo.registerGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('an error from another screen is not carried onto sign-up', (tester) async {
      repo.googleResult = const Left(AuthFailure('raw', 'network-request-failed'));
      final r = GoRouter(initialLocation: RouteNames.welcomePath, routes: [
        GoRoute(path: RouteNames.welcomePath, builder: (_, _) => const WelcomeScreen()),
        GoRoute(path: RouteNames.signupPath, builder: (_, _) => const SignupScreen()),
        GoRoute(path: RouteNames.loginPath, builder: (_, _) => const Text('PAGE login')),
      ]);
      await pump(tester, r);
      await tester.tap(find.text(l.authContinueWithGoogle));
      await tester.pumpAndSettle();
      expect(find.text(l.errNetwork), findsOneWidget, reason: 'shown where it happened');

      await tester.tap(find.text(l.welcomeCreateAccount));
      await tester.pumpAndSettle();
      expect(find.text(l.signupTitleClient), findsOneWidget);
      expect(find.text(l.errNetwork), findsNothing);
    });

    testWidgets('an existing email shows a localized message', (tester) async {
      repo.registerResult = const Left(AuthFailure('raw', 'email-already-in-use'));
      await pump(tester, router(RouteNames.signupPath, (_) => const SignupScreen()));
      await fill(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text(l.signupButton));
      await tester.pumpAndSettle();
      expect(find.text(l.errEmailInUse), findsOneWidget);
    });

    testWidgets('Google sign-up requires the terms and passes the chosen role', (tester) async {
      await pump(tester, router(RouteNames.signupPath, (_) => const SignupScreen(initialRole: 'worker')));
      await tester.tap(find.text(l.authContinueWithGoogle));
      await tester.pumpAndSettle();
      expect(repo.calls, isNot(contains('google')));
      expect(find.text(l.signupAgreeRequired), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text(l.authContinueWithGoogle));
      await tester.pump();
      expect(repo.lastRole, UserRoles.worker);
    });
  });

  group('Role selection', () {
    late MockAuth auth;
    setUp(() {
      auth = MockAuth();
      final u = MockUser();
      when(() => u.email).thenReturn('sana@example.com');
      when(() => auth.currentUser).thenReturn(u);
    });

    testWidgets('offers only client and worker, and requires a choice', (tester) async {
      await pump(tester, router(RouteNames.roleSelectionPath, (_) => const RoleSelectionScreen()),
          extra: [firebaseAuthProvider.overrideWithValue(auth)]);
      expect(find.text(l.roleClientTitle), findsOneWidget);
      expect(find.text(l.roleWorkerTitle), findsOneWidget);
      expect(find.textContaining('dmin'), findsNothing);
      expect(find.text(l.roleSelectSignedInAs('sana@example.com')), findsOneWidget);
      await tester.tap(find.text(l.continueText));
      await tester.pumpAndSettle();
      expect(find.text(l.roleSelectRequired), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('saves the chosen role', (tester) async {
      await pump(tester, router(RouteNames.roleSelectionPath, (_) => const RoleSelectionScreen()),
          extra: [firebaseAuthProvider.overrideWithValue(auth)]);
      await tester.tap(find.text(l.roleWorkerTitle));
      await tester.tap(find.text(l.continueText));
      await tester.pump();
      expect(repo.calls, ['complete']);
      expect(repo.lastRole, UserRoles.worker);
      // The button keeps its spinner until the router moves on (auth stream).
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('a locked role shows a clear message', (tester) async {
      repo.completeResult = const Left(AuthFailure('locked', 'role-locked'));
      await pump(tester, router(RouteNames.roleSelectionPath, (_) => const RoleSelectionScreen()),
          extra: [firebaseAuthProvider.overrideWithValue(auth)]);
      await tester.tap(find.text(l.roleClientTitle));
      await tester.tap(find.text(l.continueText));
      await tester.pumpAndSettle();
      expect(find.text(l.errRoleLocked), findsOneWidget);
    });

    testWidgets('use a different account signs out and returns to Welcome', (tester) async {
      await pump(tester, router(RouteNames.roleSelectionPath, (_) => const RoleSelectionScreen()),
          extra: [firebaseAuthProvider.overrideWithValue(auth)]);
      await tester.tap(find.text(l.roleSelectDifferentAccount));
      await tester.pumpAndSettle();
      expect(repo.calls, ['signOut']);
      expect(find.text('PAGE ${RouteNames.welcomePath}'), findsOneWidget);
    });

    testWidgets('signed-out visitors are sent to sign in', (tester) async {
      when(() => auth.currentUser).thenReturn(null);
      await pump(tester, router(RouteNames.roleSelectionPath, (_) => const RoleSelectionScreen()),
          extra: [firebaseAuthProvider.overrideWithValue(auth)]);
      expect(find.text(l.roleSelectSignedOutTitle), findsOneWidget);
    });
  });

  group('Forgot password', () {
    testWidgets('validates the email, sends the link and shows a neutral confirmation', (tester) async {
      await pump(tester, router(RouteNames.forgotPasswordPath, (_) => const ForgotPasswordScreen()));
      await tester.tap(find.text(l.forgotSend));
      await tester.pumpAndSettle();
      expect(find.text(l.validationEmailRequired), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), ' sana@example.com ');
      await tester.tap(find.text(l.forgotSend));
      await tester.pump();
      expect(repo.lastResetEmail, 'sana@example.com');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(l.forgotSentTitle), findsOneWidget);
      expect(find.text(l.forgotSentBody('sana@example.com')), findsOneWidget);
      expect(find.text(l.forgotResendIn(60)), findsOneWidget, reason: 'resend has a cooldown');
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(find.text(l.forgotResend), findsOneWidget);
      await tester.tap(find.text(l.forgotResend));
      await tester.pump();
      expect(repo.calls.where((c) => c == 'reset').length, 2);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('a failure shows a friendly message', (tester) async {
      repo.resetResult = const Left(NetworkFailure());
      await pump(tester, router(RouteNames.forgotPasswordPath, (_) => const ForgotPasswordScreen()));
      await tester.enterText(find.byType(TextFormField), 'sana@example.com');
      await tester.tap(find.text(l.forgotSend));
      await tester.pumpAndSettle();
      expect(find.text(l.errNetwork), findsOneWidget);
      expect(find.text(l.forgotSentTitle), findsNothing);
    });
  });

  group('Phone OTP', () {
    testWidgets('sends on open, verifies a 6-digit code, resend waits for the cooldown', (tester) async {
      await pump(tester, router(RouteNames.otpPath, (_) => const OtpVerificationScreen(phoneNumber: '+923001234567')));
      expect(repo.calls, ['sendOtp:+923001234567']);
      expect(find.text(l.otpSubtitle('300 1234567')), findsOneWidget);
      expect(find.text(l.forgotResendIn(60)), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.text(l.otpVerify));
      await tester.pump();
      expect(repo.calls, isNot(contains('verifyOtp')), reason: 'incomplete code');

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.pumpAndSettle();
      expect(repo.lastOtp, '123456');

      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle(); // let the "verified" snackbar leave
      await tester.tap(find.text(l.otpResend));
      await tester.pump();
      expect(repo.calls.where((c) => c.startsWith('sendOtp')).length, 2);
      await tester.pump(const Duration(seconds: 61));
    });
  });
}

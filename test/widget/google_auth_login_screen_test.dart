import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:skill_bridge/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:skill_bridge/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/screens/login_screen.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/test_app.dart';

class MockAuthRepositoryForTest implements AuthRepository {
  bool googleLoginCalled = false;
  String? googleLoginRole;
  int emailLoginCalls = 0;
  String? lastEmail;
  String? lastPassword;

  Either<Failure, UserEntity>? googleLoginResult;
  Either<Failure, UserEntity>? emailLoginResult;

  /// When set, email login waits on this (to test in-flight behaviour).
  Completer<void>? emailGate;

  final testUser = UserEntity(
    uid: 'google_user_123',
    email: 'test@example.com',
    displayName: 'Test Google User',
    phoneNumber: '+923001234567',
    role: 'client',
    isEmailVerified: true,
    isPhoneVerified: false,
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle({String? role}) async {
    googleLoginCalled = true;
    googleLoginRole = role;
    return googleLoginResult ?? Right(testUser);
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emailLoginCalls++;
    lastEmail = email;
    lastPassword = password;
    if (emailGate != null) await emailGate!.future;
    return emailLoginResult ?? Right(testUser);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAuthRepositoryForTest mockRepo;
  late AppLocalizations l;

  setUpAll(() async => l = await englishStrings());
  setUp(() => mockRepo = MockAuthRepositoryForTest());

  List<dynamic> overridesFor(MockAuthRepositoryForTest repo) => [
        authRepositoryProvider.overrideWithValue(repo),
        loginWithEmailUseCaseProvider.overrideWithValue(LoginWithEmailUseCase(repo)),
        loginWithGoogleUseCaseProvider.overrideWithValue(LoginWithGoogleUseCase(repo)),
      ];

  GoRouter loginRouter() => GoRouter(initialLocation: RouteNames.loginPath, routes: [
        GoRoute(path: RouteNames.loginPath, builder: (_, _) => const LoginScreen()),
        GoRoute(path: RouteNames.roleSelectionPath, builder: (_, _) => const Text('ROLE SELECTION')),
        GoRoute(path: RouteNames.welcomePath, builder: (_, _) => const Text('WELCOME')),
        GoRoute(path: RouteNames.signupPath, builder: (_, _) => const Text('SIGNUP')),
        GoRoute(path: RouteNames.forgotPasswordPath, builder: (_, _) => const Text('FORGOT')),
      ]);

  Widget buildLoginScreen({Brightness brightness = Brightness.light}) =>
      testRouterApp(router: loginRouter(), overrides: overridesFor(mockRepo), brightness: brightness);

  Future<void> enterCredentials(WidgetTester tester, String email, String password) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
  }

  group('LoginScreen', () {
    testWidgets('renders the sign-in form, Google option and links', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text(l.loginTitle), findsOneWidget);
      expect(find.text(l.loginSubtitle), findsOneWidget);
      expect(find.text(l.email), findsOneWidget);
      expect(find.text(l.password), findsOneWidget);
      expect(find.text(l.loginForgotPassword), findsOneWidget);
      expect(find.text(l.loginButton), findsOneWidget);
      expect(find.text(l.authContinueWithGoogle), findsOneWidget);
      expect(find.text(l.authOr), findsOneWidget);
      expect(find.text(l.loginNoAccount), findsOneWidget);
      expect(find.text(l.welcomeCreateAccount), findsOneWidget);
    });

    for (final b in Brightness.values) {
      testWidgets('fits a 360x640 phone without overflow (${b.name})', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildLoginScreen(brightness: b));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Continue with Google starts Firebase Google sign-in', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      // The brand header sits above the form; the page scrolls on short screens.
      await tester.ensureVisible(find.text(l.authContinueWithGoogle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.authContinueWithGoogle));
      await tester.pump();
      expect(mockRepo.googleLoginCalled, isTrue);
      expect(mockRepo.googleLoginRole, isNull, reason: 'sign-in never chooses a role');
    });

    testWidgets('shows localized validation errors and does not call login', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.loginButton));
      await tester.pumpAndSettle();
      expect(find.text(l.validationEmailRequired), findsOneWidget);
      expect(find.text(l.validationPasswordRequired), findsOneWidget);
      expect(mockRepo.emailLoginCalls, 0);

      await enterCredentials(tester, 'not-an-email', 'x');
      await tester.tap(find.text(l.loginButton));
      await tester.pumpAndSettle();
      expect(find.text(l.validationEmailInvalid), findsOneWidget);
      expect(mockRepo.emailLoginCalls, 0);
    });

    testWidgets('valid credentials call login once, trimmed', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      await enterCredentials(tester, '  user@example.com ', 'secret123');
      await tester.tap(find.text(l.loginButton));
      await tester.pump();
      expect(mockRepo.emailLoginCalls, 1);
      expect(mockRepo.lastEmail, 'user@example.com');
      expect(mockRepo.lastPassword, 'secret123');
    });

    testWidgets('a second tap while signing in does not submit again', (tester) async {
      mockRepo.emailGate = Completer<void>();
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      await enterCredentials(tester, 'user@example.com', 'secret123');
      await tester.tap(find.text(l.loginButton));
      await tester.pump();
      // Button is now loading; tapping it again and pressing done must not resubmit.
      await tester.tap(find.byType(CircularProgressIndicator).first, warnIfMissed: false);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(mockRepo.emailLoginCalls, 1);
      mockRepo.emailGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('toggling password visibility changes obscureText', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      TextField password() => tester.widget<TextField>(find.byType(TextField).at(1));
      expect(password().obscureText, isTrue);
      await tester.tap(find.byTooltip(l.authShowPassword));
      await tester.pumpAndSettle();
      expect(password().obscureText, isFalse);
      expect(find.byTooltip(l.authHidePassword), findsOneWidget);
    });

    testWidgets('wrong password shows a friendly localized message, not the raw error', (tester) async {
      mockRepo.emailLoginResult = const Left(AuthFailure('FirebaseAuthException raw text', 'invalid-credential'));
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      await enterCredentials(tester, 'user@example.com', 'wrong123');
      await tester.tap(find.text(l.loginButton));
      await tester.pumpAndSettle();
      expect(find.text(l.errInvalidCredential), findsOneWidget);
      expect(find.textContaining('FirebaseAuthException'), findsNothing);
    });

    testWidgets('an account without a profile is sent to role selection', (tester) async {
      mockRepo.emailLoginResult = const Left(AuthFailure('Finish setting up', AuthFlowCodes.needsRole));
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      await enterCredentials(tester, 'user@example.com', 'secret123');
      await tester.tap(find.text(l.loginButton));
      await tester.pumpAndSettle();
      expect(find.text('ROLE SELECTION'), findsOneWidget);
      expect(find.text(l.errGeneric), findsNothing, reason: 'needs-role is a flow, not an error');
    });
  });

  group('LoginViewModel Google Auth State Transition Tests', () {
    ProviderContainer containerFor(MockAuthRepositoryForTest repo) {
      final c = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        loginWithEmailUseCaseProvider.overrideWithValue(LoginWithEmailUseCase(repo)),
        loginWithGoogleUseCaseProvider.overrideWithValue(LoginWithGoogleUseCase(repo)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('Google sign-in cancellation does not set errorMessage banner', () async {
      mockRepo.googleLoginResult = const Left(AuthFailure('Google sign-in was cancelled.'));
      final container = containerFor(mockRepo);
      await container.read(loginViewModelProvider.notifier).loginWithGoogle();
      final state = container.read(loginViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.failure, isNull);
    });

    test('Google sign-in failure keeps the failure for a localized message', () async {
      mockRepo.googleLoginResult = const Left(AuthFailure('Network error during Google authentication.'));
      final container = containerFor(mockRepo);
      await container.read(loginViewModelProvider.notifier).loginWithGoogle();
      final state = container.read(loginViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Network error during Google authentication.');
      expect(state.failure, isA<AuthFailure>());
    });

    test('new Google account without a role sets needsRole, not an error', () async {
      mockRepo.googleLoginResult = const Left(AuthFailure('Choose', AuthFlowCodes.needsRole));
      final container = containerFor(mockRepo);
      await container.read(loginViewModelProvider.notifier).loginWithGoogle();
      final state = container.read(loginViewModelProvider);
      expect(state.needsRole, isTrue);
      expect(state.failure, isNull);
      container.read(loginViewModelProvider.notifier).consumeNeedsRole();
      expect(container.read(loginViewModelProvider).needsRole, isFalse);
    });

    test('Google sign-up passes the chosen role through', () async {
      final container = containerFor(mockRepo);
      await container.read(loginViewModelProvider.notifier).loginWithGoogle(role: UserRoles.worker);
      expect(mockRepo.googleLoginRole, UserRoles.worker);
    });
  });
}

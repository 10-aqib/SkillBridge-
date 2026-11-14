import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/features/auth/domain/usecases/auth_usecases.dart';
import 'package:skill_bridge/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:skill_bridge/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:skill_bridge/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';

Future<Either<Failure, T>> _runAuthAction<T>(
  Future<Either<Failure, T>> Function() action, {
  required String timeoutMessage,
}) async {
  try {
    return await action().timeout(const Duration(seconds: 30));
  } on TimeoutException {
    return Left(NetworkFailure(timeoutMessage));
  } catch (_) {
    return const Left(ServerFailure('The request failed. Please try again.'));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login State
// ─────────────────────────────────────────────────────────────────────────────

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  /// The failure behind [errorMessage], for localized display.
  final Failure? failure;

  /// Signed in with Firebase but no SkillBridge profile yet: ask for a role.
  final bool needsRole;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.failure,
    this.needsRole = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
    Failure? failure,
    bool? needsRole,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      failure: clearError ? null : (failure ?? this.failure),
      needsRole: needsRole ?? this.needsRole,
    );
  }
}

bool _isNeedsRole(Failure f) => f is AuthFailure && f.code == AuthFlowCodes.needsRole;

// ─────────────────────────────────────────────────────────────────────────────
// Login ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class LoginViewModel extends Notifier<LoginState> {
  late final LoginWithEmailUseCase _loginUseCase;
  late final LoginWithGoogleUseCase _loginWithGoogleUseCase;

  @override
  LoginState build() {
    _loginUseCase = ref.watch(loginWithEmailUseCaseProvider);
    _loginWithGoogleUseCase = ref.watch(loginWithGoogleUseCaseProvider);
    return const LoginState();
  }

  Future<void> login({required String email, required String password}) async {
    if (state.isLoading) return; // no duplicate submissions
    state = state.copyWith(isLoading: true, clearError: true, needsRole: false);

    final result = await _runAuthAction(
      () => _loginUseCase(email: email, password: password),
      timeoutMessage: 'Sign in timed out. Check your connection and retry.',
    );

    result.fold(
      (failure) => state = _isNeedsRole(failure)
          ? state.copyWith(isLoading: false, needsRole: true)
          : state.copyWith(
              isLoading: false,
              errorMessage: failure.message,
              failure: failure,
            ),
      (user) => state = state.copyWith(isLoading: false, isSuccess: true),
    );
  }

  Future<void> loginWithGoogle({String? role}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true, needsRole: false);

    final result = await _runAuthAction(
      () => _loginWithGoogleUseCase(role: role),
      timeoutMessage:
          'Google sign in timed out. Check your connection and retry.',
    );

    result.fold(
      (failure) {
        final isCancelled = failure is AuthFailure &&
            (failure.message.toLowerCase().contains('cancelled') ||
                failure.message.toLowerCase().contains('canceled'));
        if (_isNeedsRole(failure)) {
          state = state.copyWith(isLoading: false, needsRole: true);
        } else if (isCancelled) {
          state = state.copyWith(isLoading: false, clearError: true);
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            failure: failure,
          );
        }
      },
      (user) => state = state.copyWith(isLoading: false, isSuccess: true),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Call after navigating to role selection so the flag doesn't re-fire.
  void consumeNeedsRole() => state = state.copyWith(needsRole: false);
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Register State
// ─────────────────────────────────────────────────────────────────────────────

class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final Failure? failure;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.failure,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
    Failure? failure,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      failure: clearError ? null : (failure ?? this.failure),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class RegisterViewModel extends Notifier<RegisterState> {
  late final RegisterWithEmailUseCase _registerUseCase;

  @override
  RegisterState build() {
    _registerUseCase = ref.watch(registerWithEmailUseCaseProvider);
    return const RegisterState();
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
    String? city,
  }) async {
    if (state.isLoading) return;
    if (!UserRoles.isSelfService(role)) {
      state = state.copyWith(
        errorMessage: 'Choose client or worker.',
        failure: const AuthFailure('Choose client or worker.', 'invalid-role'),
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _runAuthAction(
      () => _registerUseCase(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
        city: city,
      ),
      timeoutMessage:
          'Registration timed out. Check your connection and retry.',
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        failure: failure,
      ),
      (user) => state = state.copyWith(isLoading: false, isSuccess: true),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final registerViewModelProvider =
    NotifierProvider<RegisterViewModel, RegisterState>(RegisterViewModel.new);

// ─────────────────────────────────────────────────────────────────────────────
// Forgot Password State & ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;
  final bool emailSent;
  final Failure? failure;

  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.emailSent = false,
    this.failure,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? emailSent,
    Failure? failure,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      emailSent: emailSent ?? this.emailSent,
      failure: clearError ? null : (failure ?? this.failure),
    );
  }
}

class ForgotPasswordViewModel extends Notifier<ForgotPasswordState> {
  late final SendPasswordResetEmailUseCase _resetUseCase;

  @override
  ForgotPasswordState build() {
    _resetUseCase = ref.watch(sendPasswordResetEmailUseCaseProvider);
    return const ForgotPasswordState();
  }

  Future<void> sendResetEmail({required String email}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _runAuthAction(
      () => _resetUseCase(email: email),
      timeoutMessage:
          'Password reset timed out. Check your connection and retry.',
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        failure: failure,
      ),
      (_) => state = state.copyWith(isLoading: false, emailSent: true),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const ForgotPasswordState();
}

final forgotPasswordViewModelProvider =
    NotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>(
      ForgotPasswordViewModel.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// OTP State & ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class OtpState {
  final bool isSending;
  final bool isVerifying;
  final String? errorMessage;
  final String? verificationId;
  final bool otpSent;
  final bool isVerified;

  const OtpState({
    this.isSending = false,
    this.isVerifying = false,
    this.errorMessage,
    this.verificationId,
    this.otpSent = false,
    this.isVerified = false,
  });

  OtpState copyWith({
    bool? isSending,
    bool? isVerifying,
    String? errorMessage,
    bool clearError = false,
    String? verificationId,
    bool? otpSent,
    bool? isVerified,
  }) {
    return OtpState(
      isSending: isSending ?? this.isSending,
      isVerifying: isVerifying ?? this.isVerifying,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      verificationId: verificationId ?? this.verificationId,
      otpSent: otpSent ?? this.otpSent,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class OtpViewModel extends Notifier<OtpState> {
  late final SendPhoneOtpUseCase _sendOtpUseCase;
  late final VerifyPhoneOtpUseCase _verifyOtpUseCase;

  @override
  OtpState build() {
    _sendOtpUseCase = ref.watch(sendPhoneOtpUseCaseProvider);
    _verifyOtpUseCase = ref.watch(verifyPhoneOtpUseCaseProvider);
    return const OtpState();
  }

  Future<void> sendOtp({required String phoneNumber}) async {
    state = state.copyWith(isSending: true, clearError: true);

    final result = await _runAuthAction(
      () => _sendOtpUseCase(phoneNumber: phoneNumber),
      timeoutMessage:
          'Sending the code timed out. Check your connection and retry.',
    );

    result.fold(
      (failure) => state = state.copyWith(
        isSending: false,
        errorMessage: failure.message,
      ),
      (verificationId) => state = state.copyWith(
        isSending: false,
        verificationId: verificationId,
        otpSent: true,
      ),
    );
  }

  Future<void> verifyOtp({required String smsCode}) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        errorMessage: 'Verification session expired. Resend OTP.',
      );
      return;
    }
    state = state.copyWith(isVerifying: true, clearError: true);

    final result = await _runAuthAction(
      () => _verifyOtpUseCase(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      ),
      timeoutMessage:
          'Code verification timed out. Check your connection and retry.',
    );

    result.fold(
      (failure) => state = state.copyWith(
        isVerifying: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(isVerifying: false, isVerified: true),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final otpViewModelProvider = NotifierProvider<OtpViewModel, OtpState>(
  OtpViewModel.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Complete profile (choose role after Google sign-up / interrupted sign-up)
// ─────────────────────────────────────────────────────────────────────────────

class CompleteProfileState {
  final bool isLoading;
  final Failure? failure;
  final bool isDone;

  const CompleteProfileState({this.isLoading = false, this.failure, this.isDone = false});
}

class CompleteProfileViewModel extends Notifier<CompleteProfileState> {
  @override
  CompleteProfileState build() => const CompleteProfileState();

  Future<void> complete({required String role}) async {
    if (state.isLoading) return;
    if (!UserRoles.isSelfService(role)) {
      state = const CompleteProfileState(
        failure: AuthFailure('Choose client or worker.', 'invalid-role'),
      );
      return;
    }
    state = const CompleteProfileState(isLoading: true);
    final result = await _runAuthAction(
      () => ref.read(completeProfileUseCaseProvider).call(role: role),
      timeoutMessage: 'Saving timed out. Check your connection and retry.',
    );
    state = result.fold(
      (failure) => CompleteProfileState(failure: failure),
      (_) => const CompleteProfileState(isDone: true),
    );
  }
}

final completeProfileViewModelProvider =
    NotifierProvider<CompleteProfileViewModel, CompleteProfileState>(
      CompleteProfileViewModel.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Email verification
// ─────────────────────────────────────────────────────────────────────────────

class EmailVerificationState {
  final bool isSending;
  final bool isChecking;
  final bool sent;
  final bool? verified;
  final Failure? failure;

  const EmailVerificationState({
    this.isSending = false,
    this.isChecking = false,
    this.sent = false,
    this.verified,
    this.failure,
  });
}

class EmailVerificationViewModel extends Notifier<EmailVerificationState> {
  @override
  EmailVerificationState build() => const EmailVerificationState();

  Future<void> resend() async {
    if (state.isSending) return;
    state = EmailVerificationState(isSending: true, verified: state.verified);
    final result = await ref.read(sendEmailVerificationUseCaseProvider).call();
    state = result.fold(
      (f) => EmailVerificationState(failure: f, verified: state.verified),
      // A fresh email supersedes an earlier "not verified yet" result, so the
      // card confirms the send instead of repeating the old message.
      (_) => const EmailVerificationState(sent: true),
    );
  }

  Future<void> refresh() async {
    if (state.isChecking) return;
    state = EmailVerificationState(isChecking: true, sent: state.sent);
    final result = await ref.read(refreshEmailVerificationUseCaseProvider).call();
    state = result.fold(
      (f) => EmailVerificationState(failure: f, sent: state.sent),
      (v) => EmailVerificationState(verified: v, sent: state.sent),
    );
  }
}

final emailVerificationViewModelProvider =
    NotifierProvider<EmailVerificationViewModel, EmailVerificationState>(
      EmailVerificationViewModel.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/features/auth/domain/usecases/auth_usecases.dart';
import 'package:skill_bridge/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:skill_bridge/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Login State
// ─────────────────────────────────────────────────────────────────────────────

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class LoginViewModel extends Notifier<LoginState> {
  late final LoginWithEmailUseCase _loginUseCase;

  @override
  LoginState build() {
    _loginUseCase = ref.watch(loginWithEmailUseCaseProvider);
    return const LoginState();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _loginUseCase(email: email, password: password);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      ),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final loginViewModelProvider =
    NotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);

// ─────────────────────────────────────────────────────────────────────────────
// Register State
// ─────────────────────────────────────────────────────────────────────────────

class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
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
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _registerUseCase(
      email: email,
      password: password,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: role,
      city: city,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      ),
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

  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.emailSent = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? emailSent,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      emailSent: emailSent ?? this.emailSent,
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
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _resetUseCase(email: email);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        emailSent: true,
      ),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const ForgotPasswordState();
}

final forgotPasswordViewModelProvider =
    NotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>(
        ForgotPasswordViewModel.new);

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

    final result = await _sendOtpUseCase(phoneNumber: phoneNumber);

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
          errorMessage: 'Verification session expired. Resend OTP.');
      return;
    }
    state = state.copyWith(isVerifying: true, clearError: true);

    final result = await _verifyOtpUseCase(
      verificationId: state.verificationId!,
      smsCode: smsCode,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isVerifying: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isVerifying: false,
        isVerified: true,
      ),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final otpViewModelProvider =
    NotifierProvider<OtpViewModel, OtpState>(OtpViewModel.new);

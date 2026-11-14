import 'package:dartz/dartz.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;

  /// Runs while still signed in (e.g. stop live location sharing and remove
  /// the shared position, which needs the account's access).
  final Future<void> Function()? beforeSignOut;
  const SignOutUseCase(this._repository, {this.beforeSignOut});

  Future<Either<Failure, void>> call() async {
    try {
      await beforeSignOut?.call();
    } catch (_) {}
    return _repository.signOut();
  }
}

class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;
  const SendPasswordResetEmailUseCase(this._repository);

  Future<Either<Failure, void>> call({required String email}) =>
      _repository.sendPasswordResetEmail(email: email);
}

class SendPhoneOtpUseCase {
  final AuthRepository _repository;
  const SendPhoneOtpUseCase(this._repository);

  /// Returns verificationId on success.
  Future<Either<Failure, String>> call({required String phoneNumber}) =>
      _repository.sendPhoneOtp(phoneNumber: phoneNumber);
}

class VerifyPhoneOtpUseCase {
  final AuthRepository _repository;
  const VerifyPhoneOtpUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String verificationId,
    required String smsCode,
  }) =>
      _repository.verifyPhoneOtp(
          verificationId: verificationId, smsCode: smsCode);
}

class UpdateUserRoleUseCase {
  final AuthRepository _repository;
  const UpdateUserRoleUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required String role,
  }) =>
      _repository.updateUserRole(uid: uid, role: role);
}

class UpdateUserProfileUseCase {
  final AuthRepository _repository;
  const UpdateUserProfileUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required Map<String, dynamic> data,
  }) =>
      _repository.updateUserProfile(uid: uid, data: data);
}

class CompleteProfileUseCase {
  final AuthRepository _repository;
  const CompleteProfileUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String role,
    String? displayName,
    String? phoneNumber,
  }) =>
      _repository.completeProfile(role: role, displayName: displayName, phoneNumber: phoneNumber);
}

class SendEmailVerificationUseCase {
  final AuthRepository _repository;
  const SendEmailVerificationUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.sendEmailVerification();
}

class RefreshEmailVerificationUseCase {
  final AuthRepository _repository;
  const RefreshEmailVerificationUseCase(this._repository);

  Future<Either<Failure, bool>> call() => _repository.refreshEmailVerification();
}

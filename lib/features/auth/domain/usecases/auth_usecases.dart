import 'package:dartz/dartz.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;
  const SignOutUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.signOut();
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

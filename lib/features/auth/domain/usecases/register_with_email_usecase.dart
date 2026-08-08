import 'package:dartz/dartz.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';

class RegisterWithEmailUseCase {
  final AuthRepository _repository;
  const RegisterWithEmailUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
    String? city,
  }) =>
      _repository.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
        city: city,
      );
}

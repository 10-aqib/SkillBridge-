import 'package:dartz/dartz.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository _repository;
  const LoginWithEmailUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) =>
      _repository.loginWithEmail(email: email, password: password);
}

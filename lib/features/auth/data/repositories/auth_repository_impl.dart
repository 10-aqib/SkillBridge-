// ignore_for_file: prefer_initializing_formals
import 'package:dartz/dartz.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/core/network/network_info.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
/// Bridges the data layer to the domain layer with error handling.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Stream<UserEntity?> get authStateChanges =>
      _remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      Logger.e('getCurrentUser error', e);
      return Left(ServerFailure('Failed to get current user'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
    String? city,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await _remoteDataSource.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
        city: city,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      Logger.e('registerWithEmail error', e);
      return Left(ServerFailure('Registration failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await _remoteDataSource.loginWithEmail(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      Logger.e('loginWithEmail error', e);
      return Left(AuthFailure('Login failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      Logger.e('signOut error', e);
      return Left(ServerFailure('Sign out failed.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      Logger.e('sendPasswordResetEmail error', e);
      return Left(ServerFailure('Failed to send reset email. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, String>> sendPhoneOtp({
    required String phoneNumber,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final verificationId =
          await _remoteDataSource.sendPhoneOtp(phoneNumber: phoneNumber);
      return Right(verificationId);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      Logger.e('sendPhoneOtp error', e);
      return Left(ServerFailure('Failed to send OTP. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remoteDataSource.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      Logger.e('verifyPhoneOtp error', e);
      return Left(AuthFailure('OTP verification failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole({
    required String uid,
    required String role,
  }) async {
    try {
      await _remoteDataSource.updateUserRole(uid: uid, role: role);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      Logger.e('updateUserRole error', e);
      return Left(ServerFailure('Failed to update role.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFcmToken({
    required String uid,
    required String token,
  }) async {
    try {
      await _remoteDataSource.updateFcmToken(uid: uid, token: token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      Logger.e('updateFcmToken error', e);
      return Left(ServerFailure('Failed to update notification token.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await _remoteDataSource.updateUserProfile(
        uid: uid,
        data: data,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      Logger.e('updateUserProfile error', e);
      return Left(ServerFailure('Failed to update profile.'));
    }
  }
}

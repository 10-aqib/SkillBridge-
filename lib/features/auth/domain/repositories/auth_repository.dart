import 'package:dartz/dartz.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

/// Abstract contract for authentication operations.
/// Implemented by AuthRepositoryImpl in the data layer.
abstract class AuthRepository {
  /// Returns a stream of the currently signed-in user (null when signed out).
  Stream<UserEntity?> get authStateChanges;

  /// Returns the currently signed-in user, or null if not authenticated.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Registers a new user with email/password and creates their Firestore profile.
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
    String? city,
  });

  /// Signs in an existing user with email/password.
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Signs out the current user.
  Future<Either<Failure, void>> signOut();

  /// Sends a password reset email.
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});

  /// Sends OTP to the given phone number.
  Future<Either<Failure, String>> sendPhoneOtp({required String phoneNumber});

  /// Verifies OTP and marks phone as verified.
  Future<Either<Failure, void>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Updates the user role (called after role selection screen).
  Future<Either<Failure, void>> updateUserRole({
    required String uid,
    required String role,
  });

  /// Updates the FCM token for push notifications.
  Future<Either<Failure, void>> updateFcmToken({
    required String uid,
    required String token,
  });

  /// Updates the user profile in Firestore.
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  });
}

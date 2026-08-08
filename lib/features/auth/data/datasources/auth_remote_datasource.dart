// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';

/// Remote data source that communicates with Firebase Auth and Firestore.
abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> getCurrentUser();
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
    String? city,
  });
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({required String email});
  Future<String> sendPhoneOtp({required String phoneNumber});
  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<void> updateUserRole({required String uid, required String role});
  Future<void> updateFcmToken({required String uid, required String token});
  Future<UserModel> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc = await _usersCollection.doc(firebaseUser.uid).get();
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      } catch (e) {
        Logger.e('authStateChanges error', e);
        return null;
      }
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    try {
      final doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to get current user', e.code);
    }
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
    String? city,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user!;

      // Update Firebase Auth display name
      await firebaseUser.updateDisplayName(displayName);

      // Create Firestore user document
      final userModel = UserModel.newUser(
        uid: firebaseUser.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
        city: city,
      );

      await _usersCollection
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());

      Logger.i('User registered: ${firebaseUser.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Registration failed', e.code);
    }
  }

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user!;

      final doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) {
        throw const ServerException(
            'User profile not found. Please contact support.');
      }

      final userModel = UserModel.fromFirestore(doc);

      // Check if account is active
      if (!userModel.isActive) {
        await _auth.signOut();
        throw const AuthException(
            'Your account has been suspended. Contact support.');
      }

      Logger.i('User logged in: ${firebaseUser.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Login failed', e.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.i('User signed out');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Logger.i('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    }
  }

  @override
  Future<String> sendPhoneOtp({required String phoneNumber}) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification on Android
        if (!completer.isCompleted && credential.verificationId != null) {
          completer.complete(credential.verificationId!);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
              AuthException(_mapFirebaseAuthError(e.code), e.code));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        Logger.i('OTP sent, verificationId: $verificationId');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  @override
  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }

      // Mark phone as verified in Firestore
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _usersCollection.doc(uid).update({
          'isPhoneVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      Logger.i('Phone OTP verified successfully');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    }
  }

  @override
  Future<void> updateUserRole(
      {required String uid, required String role}) async {
    try {
      await _usersCollection.doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update role', e.code);
    }
  }

  @override
  Future<void> updateFcmToken(
      {required String uid, required String token}) async {
    try {
      await _usersCollection.doc(uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update FCM token', e.code);
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final doc = await _usersCollection.doc(uid).get();
      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update profile', e.code);
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Use format: +92XXXXXXXXXX';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP session expired. Please request a new one.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

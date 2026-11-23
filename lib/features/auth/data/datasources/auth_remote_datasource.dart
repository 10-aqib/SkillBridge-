// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/core/services/local_account_data.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/features/notifications/data/services/push_notification_service.dart' show PushTokenStore;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skill_bridge/core/constants/app_constants.dart';

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
  Future<UserModel> loginWithGoogle({String? role});
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

  /// Creates (or finishes) the SkillBridge profile for the signed-in Firebase
  /// user with a client/worker role. Used after Google sign-up and to recover
  /// an interrupted registration.
  Future<UserModel> completeProfile({
    required String role,
    String? displayName,
    String? phoneNumber,
  });

  /// Sends Firebase's verification email to the signed-in user.
  Future<void> sendEmailVerification();

  /// Reloads the Firebase user; if the email is now verified, records it on
  /// the profile. Returns the current verification state.
  Future<bool> refreshEmailVerification();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<UserModel?> get authStateChanges {
    late StreamController<UserModel?> controller;
    StreamSubscription? authSub;
    StreamSubscription? docSub;

    controller = StreamController<UserModel?>.broadcast(
      onListen: () {
        authSub = _auth.authStateChanges().listen(
          (firebaseUser) {
            docSub?.cancel();
            if (firebaseUser == null) {
              controller.add(null);
            } else {
              docSub = _usersCollection
                  .doc(firebaseUser.uid)
                  .snapshots()
                  .listen(
                    (doc) {
                      if (!doc.exists) {
                        controller.add(null);
                      } else {
                        try {
                          controller.add(UserModel.fromFirestore(doc));
                        } catch (e) {
                          Logger.e('authStateChanges error', e);
                          controller.add(null);
                        }
                      }
                    },
                    onError: (e) {
                      Logger.e('authStateChanges snapshot error', e);
                      controller.add(null);
                    },
                  );
            }
          },
          onError: (e) {
            Logger.e('authStateChanges auth error', e);
            controller.add(null);
          },
        );
      },
      onCancel: () {
        authSub?.cancel();
        docSub?.cancel();
      },
    );

    return controller.stream;
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
    if (!UserRoles.isSelfService(role)) {
      throw const AuthException('Choose client or worker.', 'invalid-role');
    }
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
        // New clients get a short onboarding; workers use the profile setup.
        onboardingCompleted: role == UserRoles.client ? false : null,
      );

      await _usersCollection.doc(firebaseUser.uid).set({
        ...userModel.toFirestore(),
        'authProvider': 'password',
      });

      // Best effort: the account works without it; the profile offers resend.
      try {
        await firebaseUser.sendEmailVerification();
      } catch (e) {
        Logger.w('Verification email not sent: $e');
      }

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
        // Account exists but registration was interrupted before the profile
        // was saved. Keep the session and let the person finish (choose role)
        // instead of creating a second account.
        throw const AuthException('Finish setting up your account.', AuthFlowCodes.needsRole);
      }

      final userModel = UserModel.fromFirestore(doc);

      // Check if account is active
      if (!userModel.isActive) {
        await _auth.signOut();
        throw const AuthException(
          'Your account has been suspended. Contact support.',
        );
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

  static const String _serverClientId =
      '140302201182-bioc9sfe6kjc3iq68896g588reu0eip2.apps.googleusercontent.com';

  @override
  Future<UserModel> loginWithGoogle({String? role}) async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        _googleSignInInitialization ??= _googleSignIn.initialize(
          serverClientId: _serverClientId,
        );
        await _googleSignInInitialization;
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Could not retrieve Google user profile.');
      }

      final doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) {
        // New Google account. Without a chosen client/worker role, don't
        // create a profile yet (the old code stored role '' which the rules
        // then refused to change). The UI asks for the role and calls
        // completeProfile().
        if (!UserRoles.isSelfService(role)) {
          throw const AuthException('Choose how you will use SkillBridge.', AuthFlowCodes.needsRole);
        }
        final userModel = await completeProfile(role: role!);
        Logger.i('New user created via Google Sign-In: ${firebaseUser.uid}');
        return userModel;
      } else {
        final userModel = UserModel.fromFirestore(doc);
        if (!userModel.isActive) {
          await _auth.signOut();
          if (!kIsWeb) {
            await _googleSignIn.signOut();
          }
          throw const AuthException(
            'Your account has been suspended. Contact support.',
            'suspended',
          );
        }

        final updateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        };

        if ((userModel.photoUrl == null || userModel.photoUrl!.isEmpty) &&
            firebaseUser.photoURL != null &&
            firebaseUser.photoURL!.isNotEmpty) {
          updateData['photoUrl'] = firebaseUser.photoURL;
        }

        if (userModel.displayName.trim().isEmpty &&
            firebaseUser.displayName != null &&
            firebaseUser.displayName!.trim().isNotEmpty) {
          updateData['displayName'] = firebaseUser.displayName!.trim();
        }

        await _usersCollection.doc(firebaseUser.uid).update(updateData);
        Logger.i('Existing user logged in via Google: ${firebaseUser.uid}');
        return userModel;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Google sign in was cancelled', 'cancelled');
      }
      throw AuthException(
        e.description ?? 'Google sign in failed',
        e.code.name,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException('Google Login failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Stop pushes to this phone for this account (best effort, quick).
      final uid = _auth.currentUser?.uid;
      if (uid != null) await PushTokenStore.removeThisDevice(uid);
      // This account's cached listings, queued actions and searches.
      await LocalAccountData.clear();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      Logger.i('User signed out');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (AppConstants.isStaffEmail(email)) {
      throw const AuthException('Staff passwords can\'t be reset by email.', 'staff-reset-blocked');
    }
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
            AuthException(_mapFirebaseAuthError(e.code), e.code),
          );
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
        try {
          await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          // A number was confirmed before: this replaces it.
          if (e.code != 'provider-already-linked') rethrow;
          await currentUser.updatePhoneNumber(credential);
        }
        // Fresh sign-in token with the phone number in it: the rules only
        // let a public profile say "phone verified" when the token does.
        await currentUser.getIdToken(true);
      } else {
        await _auth.signInWithCredential(credential);
      }

      // Mark the phone as verified in Firestore, with the exact number that
      // received the code.
      final uid = _auth.currentUser?.uid;
      final phone = _auth.currentUser?.phoneNumber;
      if (uid != null) {
        await _usersCollection.doc(uid).update({
          'isPhoneVerified': true,
          if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      Logger.i('Phone OTP verified successfully');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    }
  }

  @override
  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    if (!UserRoles.isSelfService(role)) {
      throw const ServerException('Choose client or worker.', 'invalid-role');
    }
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
  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) async {
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
      try {
        await _usersCollection.doc(uid).update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          await _usersCollection.doc(uid).set({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }
      final doc = await _usersCollection.doc(uid).get();
      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update profile', e.code);
    }
  }

  @override
  Future<UserModel> completeProfile({
    required String role,
    String? displayName,
    String? phoneNumber,
  }) async {
    if (!UserRoles.isSelfService(role)) {
      throw const AuthException('Choose client or worker.', 'invalid-role');
    }
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const AuthException('Please sign in again.', 'no-current-user');
    }
    try {
      final ref = _usersCollection.doc(firebaseUser.uid);
      final doc = await ref.get();
      if (doc.exists) {
        final existing = UserModel.fromFirestore(doc);
        final storedRole = (doc.data()?['role'] as String?) ?? '';
        if (storedRole == role) return existing;
        if (storedRole.isNotEmpty) {
          // Roles can't be switched once chosen (also enforced by the rules).
          throw const AuthException('This account already has a role.', 'role-locked');
        }
        await ref.update({
          'role': role,
          if (role == UserRoles.client) 'onboardingCompleted': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return UserModel.fromFirestore(await ref.get());
      }

      final name = (displayName ?? firebaseUser.displayName ?? '').trim();
      final isGoogle = firebaseUser.providerData.any((p) => p.providerId == 'google.com');
      final userModel = UserModel.newUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: name,
        phoneNumber: phoneNumber ?? firebaseUser.phoneNumber ?? '',
        role: role,
        photoUrl: firebaseUser.photoURL,
        isEmailVerified: firebaseUser.emailVerified,
        onboardingCompleted: role == UserRoles.client ? false : null,
      );
      await ref.set({
        ...userModel.toFirestore(),
        'authProvider': isGoogle ? 'google' : 'password',
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      return userModel;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not save your profile', e.code);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in again.', 'no-current-user');
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    }
  }

  @override
  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      if (verified) {
        await _usersCollection.doc(user.uid).update({
          'isEmailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return verified;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not refresh verification', e.code);
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email or password is incorrect.';
      case 'account-exists-with-different-credential':
        return 'This email is already registered with a different sign-in method.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign in was cancelled';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
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
      case 'code-expired':
        return 'OTP session expired. Please request a new one.';
      case 'credential-already-in-use':
        return 'This number is already used by another SkillBridge account.';
      case 'quota-exceeded':
        return 'Too many codes were sent. Please try again later.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
      case 'invalid-app-credential':
        return 'Phone verification is not set up for this app yet.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

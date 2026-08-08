import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/providers/analytics_providers.dart';
import 'package:skill_bridge/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:skill_bridge/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:skill_bridge/features/auth/domain/usecases/auth_usecases.dart';
import 'package:skill_bridge/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:skill_bridge/features/auth/domain/usecases/register_with_email_usecase.dart';

// ── Data Source ──────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

// ── Repository ───────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ── Use Cases ─────────────────────────────────────────────────────────────────

final loginWithEmailUseCaseProvider = Provider<LoginWithEmailUseCase>((ref) {
  return LoginWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final registerWithEmailUseCaseProvider =
    Provider<RegisterWithEmailUseCase>((ref) {
  return RegisterWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase>((ref) {
  return SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider));
});

final sendPhoneOtpUseCaseProvider = Provider<SendPhoneOtpUseCase>((ref) {
  return SendPhoneOtpUseCase(ref.watch(authRepositoryProvider));
});

final verifyPhoneOtpUseCaseProvider = Provider<VerifyPhoneOtpUseCase>((ref) {
  return VerifyPhoneOtpUseCase(ref.watch(authRepositoryProvider));
});

final updateUserRoleUseCaseProvider = Provider<UpdateUserRoleUseCase>((ref) {
  return UpdateUserRoleUseCase(ref.watch(authRepositoryProvider));
});

final updateUserProfileUseCaseProvider =
    Provider<UpdateUserProfileUseCase>((ref) {
  return UpdateUserProfileUseCase(ref.watch(authRepositoryProvider));
});

// ── Auth State Stream ─────────────────────────────────────────────────────────

/// Streams the current authenticated user. Null means signed out.
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authStateSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<UserEntity?>>(authStateProvider, (previous, next) {
    next.whenData((user) {
      final analytics = ref.read(analyticsServiceProvider);
      final crashlytics = ref.read(crashlyticsServiceProvider);
      if (user != null) {
        analytics.setUserId(user.uid);
        analytics.setUserRole(user.role);
        crashlytics.setUserId(user.uid);
        crashlytics.setUserRole(user.role);
      } else {
        analytics.setUserId(null);
        crashlytics.setUserId(null);
      }
    });
  });
});

/// Convenience provider — returns true if a user is signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Returns the currently signed-in user entity (or null).
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

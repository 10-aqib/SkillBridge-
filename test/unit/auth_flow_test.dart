// Mocking Firestore reference/snapshot classes (sealed for implementers) is
// intentional here: these are mocked unit tests, not Firebase integration tests.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skill_bridge/config/router/auth_redirect.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/test_app.dart';

// ── Firebase mocks (mocked unit tests — not a real Firebase integration) ──
class MockAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockCredential extends Mock implements UserCredential {}
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocRef extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockSnap extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockUserInfo extends Mock implements UserInfo {}

UserEntity user({
  String role = 'client',
  bool active = true,
  bool? onboarding,
  WorkerProfileEntity? worker,
}) =>
    UserEntity(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'A',
      phoneNumber: '',
      role: role,
      isEmailVerified: false,
      isPhoneVerified: false,
      isActive: active,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      onboardingCompleted: onboarding,
      workerProfile: worker,
    );

const completeWorker = WorkerProfileEntity(
  headline: 'Electrician',
  bio: 'Ten years of house wiring.',
  categoryId: 'electrician',
  categoryName: 'Electrician',
  city: 'Lahore',
);

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await englishStrings();
    registerFallbackValue(<String, dynamic>{});
  });

  group('navigation guards (resolveAuthRedirect)', () {
    String? go(String location, {UserEntity? u, bool loading = false}) =>
        resolveAuthRedirect(isLoading: loading, user: u, location: location);

    test('while auth loads, everything waits on splash', () {
      expect(go('/client/home', loading: true), RouteNames.splashPath);
      expect(go(RouteNames.splashPath, loading: true), isNull);
    });

    test('signed-out people reach auth screens; protected routes go to Welcome', () {
      for (final p in kAuthRoutes) {
        expect(go(p), isNull, reason: p);
      }
      expect(go(RouteNames.clientHomePath), RouteNames.welcomePath);
      expect(go(RouteNames.workerProfileSetupPath), RouteNames.welcomePath);
      expect(go(RouteNames.otpPath), RouteNames.welcomePath);
    });

    test('signed-in people are sent to their role home from auth screens', () {
      expect(go(RouteNames.loginPath, u: user()), RouteNames.clientHomePath);
      expect(go(RouteNames.welcomePath, u: user(role: 'worker')), RouteNames.workerProfileSetupPath);
      expect(go(RouteNames.splashPath, u: user(role: 'worker', worker: completeWorker)), RouteNames.workerHomePath);
    });

    test('new clients see onboarding once; legacy clients (no flag) do not', () {
      expect(go(RouteNames.signupPath, u: user(onboarding: false)), RouteNames.clientOnboardingPath);
      expect(go(RouteNames.signupPath, u: user(onboarding: true)), RouteNames.clientHomePath);
      expect(go(RouteNames.signupPath, u: user()), RouteNames.clientHomePath);
    });

    test('a profile without a role must choose one', () {
      expect(go(RouteNames.loginPath, u: user(role: '')), RouteNames.roleSelectionPath);
      expect(go(RouteNames.roleSelectionPath, u: user(role: '')), isNull);
      expect(go('/client/home', u: user(role: '')), RouteNames.roleSelectionPath);
    });

    test('suspended accounts are kept on signed-out screens', () {
      expect(go(RouteNames.clientHomePath, u: user(active: false)), RouteNames.loginPath);
      expect(go(RouteNames.loginPath, u: user(active: false)), isNull);
    });

    test('cross-role areas are blocked', () {
      expect(go('/worker/home', u: user()), RouteNames.clientHomePath);
      expect(go('/client/home', u: user(role: 'worker', worker: completeWorker)), RouteNames.workerHomePath);
      expect(go('/admin/dashboard', u: user()), RouteNames.clientHomePath);
    });

    test('clients CAN open a public worker profile (/worker-profile/… is not the worker area)', () {
      // Regression: startsWith('/worker') used to bounce clients back home.
      expect(go('/worker-profile/abc123', u: user()), isNull);
    });

    test('signed-in people can open phone verification (OTP)', () {
      expect(go(RouteNames.otpPath, u: user()), isNull);
    });
  });

  group('validators and phone numbers', () {
    test('Pakistani mobile numbers normalise to +92', () {
      for (final input in ['03001234567', '3001234567', '+923001234567', '923001234567', '0300 123-4567', '0092 300 1234567']) {
        expect(PakPhone.normalize(input), '+923001234567', reason: input);
      }
      for (final bad in ['', '123', '04001234567', '+9230012345678', 'abc']) {
        expect(PakPhone.normalize(bad), isNull, reason: bad);
      }
      expect(PakPhone.toLocalDisplay('+923001234567'), '300 1234567');
    });

    test('form validators return localized messages', () {
      final v = AuthValidators(l);
      expect(v.email(''), l.validationEmailRequired);
      expect(v.email('a@b'), l.validationEmailInvalid);
      expect(v.email('a@b.co'), isNull);
      expect(v.newPassword('short1'), l.validationPasswordWeak);
      expect(v.newPassword('longenough'), l.validationPasswordWeak, reason: 'needs a number');
      expect(v.newPassword('longenough1'), isNull);
      expect(v.name(' '), l.validationNameRequired);
      expect(v.name('A'), l.validationNameLength);
      expect(v.phone('123'), l.validationPhoneInvalid);
      expect(v.optionalPhone(''), isNull);
    });

    test('auth failures map to friendly copy, never raw text', () {
      expect(authErrorText(l, const AuthFailure('raw', 'invalid-credential')), l.errInvalidCredential);
      expect(authErrorText(l, const AuthFailure('raw', 'email-already-in-use')), l.errEmailInUse);
      expect(authErrorText(l, const AuthFailure('raw', 'too-many-requests')), l.errTooManyRequests);
      expect(authErrorText(l, const AuthFailure('Your account has been suspended.', null)), l.errSuspended);
      expect(authErrorText(l, const NetworkFailure()), l.errNetwork);
      expect(authErrorText(l, const ServerFailure('PERMISSION_DENIED: blah')), l.errGeneric);
    });

    test('only client and worker are self-service roles', () {
      expect(UserRoles.isSelfService('client'), isTrue);
      expect(UserRoles.isSelfService('worker'), isTrue);
      for (final r in ['admin', 'SUPER_ADMIN', '', null]) {
        expect(UserRoles.isSelfService(r), isFalse);
      }
    });
  });

  group('AuthRemoteDataSource (mocked Firebase)', () {
    late MockAuth auth;
    late MockFirestore db;
    late MockCollection users;
    late MockDocRef docRef;
    late MockSnap snap;
    late MockUser fbUser;
    late AuthRemoteDataSourceImpl ds;

    setUp(() {
      auth = MockAuth();
      db = MockFirestore();
      users = MockCollection();
      docRef = MockDocRef();
      snap = MockSnap();
      fbUser = MockUser();
      when(() => db.collection('users')).thenReturn(users);
      when(() => users.doc(any())).thenReturn(docRef);
      when(() => docRef.get()).thenAnswer((_) async => snap);
      when(() => docRef.set(any())).thenAnswer((_) async {});
      when(() => docRef.update(any())).thenAnswer((_) async {});
      when(() => fbUser.uid).thenReturn('u1');
      when(() => fbUser.email).thenReturn('a@b.com');
      when(() => fbUser.displayName).thenReturn('Sana Ahmed');
      when(() => fbUser.phoneNumber).thenReturn(null);
      when(() => fbUser.photoURL).thenReturn(null);
      when(() => fbUser.emailVerified).thenReturn(true);
      final info = MockUserInfo();
      when(() => info.providerId).thenReturn('google.com');
      when(() => fbUser.providerData).thenReturn([info]);
      when(() => auth.currentUser).thenReturn(fbUser);
      ds = AuthRemoteDataSourceImpl(auth: auth, firestore: db);
    });

    test('registration with an admin role is rejected before any account is created', () async {
      await expectLater(
        ds.registerWithEmail(email: 'a@b.com', password: 'x', displayName: 'A', phoneNumber: '', role: 'admin'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-role')),
      );
      verifyNever(() => auth.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')));
    });

    test('email registration saves the chosen role, flags client onboarding, sends verification', () async {
      final cred = MockCredential();
      when(() => cred.user).thenReturn(fbUser);
      when(() => auth.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => cred);
      when(() => fbUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => fbUser.sendEmailVerification()).thenAnswer((_) async {});

      await ds.registerWithEmail(
          email: 'a@b.com', password: 'secret123', displayName: 'Sana', phoneNumber: '+923001234567', role: 'client');

      final saved = verify(() => docRef.set(captureAny())).captured.single as Map<String, dynamic>;
      expect(saved['role'], 'client');
      expect(saved['onboardingCompleted'], isFalse);
      expect(saved['rating'], 0, reason: 'no invented rating on new profiles');
      expect(saved.containsKey('cnicNumber'), isFalse);
      verify(() => fbUser.sendEmailVerification()).called(1);
    });

    test('email sign-in with no profile keeps the session and asks for a role', () async {
      final cred = MockCredential();
      when(() => cred.user).thenReturn(fbUser);
      when(() => auth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => cred);
      when(() => snap.exists).thenReturn(false);
      await expectLater(
        ds.loginWithEmail(email: 'a@b.com', password: 'secret123'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthFlowCodes.needsRole)),
      );
      verifyNever(() => auth.signOut());
    });

    test('completeProfile creates a new profile with the chosen role (Google account)', () async {
      when(() => snap.exists).thenReturn(false);
      await ds.completeProfile(role: 'worker');
      final saved = verify(() => docRef.set(captureAny())).captured.single as Map<String, dynamic>;
      expect(saved['role'], 'worker');
      expect(saved['displayName'], 'Sana Ahmed');
      expect(saved['authProvider'], 'google');
      expect(saved.containsKey('onboardingCompleted'), isFalse, reason: 'workers use profile setup');
    });

    test('completeProfile fills an empty legacy role once', () async {
      when(() => snap.exists).thenReturn(true);
      when(() => snap.id).thenReturn('u1');
      when(() => snap.data()).thenReturn({'uid': 'u1', 'role': '', 'email': 'a@b.com'});
      await ds.completeProfile(role: 'client');
      final update = verify(() => docRef.update(captureAny())).captured.single as Map;
      expect(update['role'], 'client');
      expect(update['onboardingCompleted'], isFalse);
    });

    test('completeProfile never switches an existing role', () async {
      when(() => snap.exists).thenReturn(true);
      when(() => snap.id).thenReturn('u1');
      when(() => snap.data()).thenReturn({'uid': 'u1', 'role': 'client', 'email': 'a@b.com'});
      await expectLater(
        ds.completeProfile(role: 'worker'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'role-locked')),
      );
      verifyNever(() => docRef.update(any()));
      verifyNever(() => docRef.set(any()));
    });

    test('completeProfile and updateUserRole refuse admin', () async {
      await expectLater(ds.completeProfile(role: 'admin'), throwsA(isA<AuthException>()));
      await expectLater(ds.updateUserRole(uid: 'u1', role: 'admin'), throwsA(isA<ServerException>()));
      verifyNever(() => docRef.update(any()));
    });

    test('refreshEmailVerification records verification on the profile', () async {
      when(() => fbUser.reload()).thenAnswer((_) async {});
      expect(await ds.refreshEmailVerification(), isTrue);
      final update = verify(() => docRef.update(captureAny())).captured.single as Map;
      expect(update['isEmailVerified'], isTrue);
    });
  });
}

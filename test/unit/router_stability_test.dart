import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skill_bridge/config/router/app_router.dart';
import 'package:skill_bridge/config/router/auth_redirect.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

UserModel _client({String address = ''}) => UserModel(
      uid: 'c1',
      email: 'c1@example.com',
      displayName: 'Client',
      phoneNumber: '',
      role: 'client',
      isEmailVerified: true,
      isPhoneVerified: false,
      isActive: true,
      address: address,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

/// The auth stream re-emits on every profile save. Rebuilding the router on
/// each emission sent people back to the start screen (Edit profile → Save
/// landed on Home; worker setup restarted after each step).
void main() {
  test('profile updates keep the same router instance', () async {
    final auth = StreamController<UserEntity?>.broadcast();
    addTearDown(auth.close);
    final container = ProviderContainer(overrides: [
      firebaseAnalyticsProvider.overrideWithValue(_MockAnalytics()),
      authStateProvider.overrideWith((ref) => auth.stream),
    ]);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    auth.add(_client());
    await pumpEventQueue();
    auth.add(_client(address: 'Gulberg III'));
    await pumpEventQueue();
    auth.add(null); // sign-out also only re-runs the redirect
    await pumpEventQueue();

    expect(container.read(routerProvider), same(router));
  });

  group('authRedirectKey', () {
    String key(UserEntity? u) => authRedirectKey(isLoading: false, user: u);

    test('ordinary profile edits do not re-run redirects', () {
      expect(key(_client(address: 'Gulberg')), key(_client(address: 'DHA Phase 5')));
    });

    test('sign-in, sign-out and loading do', () {
      expect(key(null), isNot(key(_client())));
      expect(authRedirectKey(isLoading: true, user: null), isNot(key(null)));
    });

    test('finishing onboarding and choosing a role do', () {
      final fresh = UserModel(
        uid: 'c1', email: 'c1@example.com', displayName: 'Client', phoneNumber: '', role: '',
        isEmailVerified: true, isPhoneVerified: false, isActive: true,
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      final client = fresh.copyWithRole('client', onboardingCompleted: false);
      final onboarded = client.copyWithRole('client', onboardingCompleted: true);
      expect(key(fresh), isNot(key(client)));
      expect(key(client), isNot(key(onboarded)));
    });
  });
}

extension on UserModel {
  UserModel copyWithRole(String role, {bool? onboardingCompleted}) => UserModel(
        uid: uid, email: email, displayName: displayName, phoneNumber: phoneNumber, role: role,
        isEmailVerified: isEmailVerified, isPhoneVerified: isPhoneVerified, isActive: isActive,
        createdAt: createdAt, updatedAt: updatedAt, onboardingCompleted: onboardingCompleted,
      );
}

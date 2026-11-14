// Phase 4B: signing out first stops live location sharing (while the
// account can still remove its shared position). Mocked repository.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:skill_bridge/features/auth/domain/usecases/auth_usecases.dart';

class _Repo extends Mock implements AuthRepository {}

void main() {
  test('the hook runs before signing out', () async {
    final order = <String>[];
    final repo = _Repo();
    when(repo.signOut).thenAnswer((_) async {
      order.add('signOut');
      return const Right<Failure, void>(null);
    });
    await SignOutUseCase(repo, beforeSignOut: () async => order.add('stopSharing')).call();
    expect(order, ['stopSharing', 'signOut']);
  });

  test('a failing hook never blocks signing out', () async {
    final repo = _Repo();
    when(repo.signOut).thenAnswer((_) async => const Right<Failure, void>(null));
    final result = await SignOutUseCase(repo, beforeSignOut: () async => throw Exception('offline')).call();
    expect(result.isRight(), isTrue);
    verify(repo.signOut).called(1);
  });
}

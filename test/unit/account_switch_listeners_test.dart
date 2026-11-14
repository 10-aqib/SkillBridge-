// A refused read seen by one account must not stick to the next account in
// the same app session (found in the Phase 3B emulator run: after a client
// signed out and a worker signed in, an open job showed "no longer
// available"). Mocked data source, not Firebase.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';

import '../helpers/fake_job_datasource.dart';
import '../helpers/fake_job_feed_source.dart';
import '../helpers/job_fixtures.dart';

class _Account extends Notifier<UserEntity?> {
  @override
  UserEntity? build() => testUser('client_1');
  void switchTo(UserEntity? u) => state = u;
}

final _account = NotifierProvider<_Account, UserEntity?>(_Account.new);

class _RefusesFirstRead extends FakeJobDataSource {
  int reads = 0;
  @override
  Stream<JobModel?> watchJob(String jobId) {
    reads++;
    return reads == 1 ? Stream.error(firestoreError('permission-denied')) : Stream.value(testJob(jobId));
  }
}

void main() {
  test('the job listener restarts for a new account instead of keeping the old refusal', () async {
    final ds = _RefusesFirstRead();
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWith((ref) => ref.watch(_account)),
      jobRemoteDataSourceProvider.overrideWithValue(ds),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(jobByIdProvider('j1'), (_, _) {});
    addTearDown(sub.close);

    await Future<void>.delayed(Duration.zero);
    expect(container.read(jobByIdProvider('j1')).hasError, isTrue);

    container.read(_account.notifier).switchTo(testUser('w1', role: 'worker'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final after = container.read(jobByIdProvider('j1'));
    expect(after.hasError, isFalse);
    expect(after.value?.id, 'j1');
    expect(ds.reads, 2);
  });
}

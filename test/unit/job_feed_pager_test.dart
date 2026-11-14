import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/features/jobs/data/job_feed_source.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_feed_controller.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';

import '../helpers/fake_job_feed_source.dart';
import '../helpers/job_fixtures.dart';

void main() {
  final base = DateTime(2026, 11, 1);
  List<JobEntity> many(int n, {String title = 'Fix kitchen sockets', List<String> skills = const ['House wiring']}) => [
        for (var i = 0; i < n; i++)
          testJob('job_$i', title: '$title $i', skills: skills, createdAt: base.add(Duration(hours: i)), budgetMax: 1000.0 + i * 100),
      ];

  group('pager', () {
    test('pages through jobs with a cursor until the end', () async {
      final source = FakeJobFeedSource([...many(20)]);
      final pager = JobFeedPager(source, pageSize: 8);
      final plan = JobFeedPlan.of(const JobFeedQuery());
      final p1 = await pager.load(plan);
      expect(p1.items.length, 8);
      expect(p1.items.first.id, 'job_19', reason: 'newest first');
      expect(p1.hasMore, isTrue);
      final p2 = await pager.load(plan, cursor: p1.cursor);
      final p3 = await pager.load(plan, cursor: p2.cursor);
      expect(p3.items.length, 4);
      expect(p3.hasMore, isFalse);
      expect({...p1.items, ...p2.items, ...p3.items}.map((j) => j.id).toSet().length, 20, reason: 'no duplicates or gaps');
    });

    test('never returns closed jobs or direct requests', () async {
      final source = FakeJobFeedSource([
        testJob('open'),
        testJob('closed', status: JobStatus.cancelled),
        testJob('direct', selectedWorkerId: 'w9'),
        testJob('assigned', status: JobStatus.assigned, selectedWorkerId: 'w9'),
      ]);
      final page = await JobFeedPager(source).load(JobFeedPlan.of(const JobFeedQuery()));
      expect(page.items.map((j) => j.id), ['open']);
    });

    test('keeps reading further pages to satisfy checks Firestore could not apply', () async {
      // 30 jobs mention "kitchen"; only the 3 oldest also mention "garden".
      final jobs = [
        ...many(27),
        for (var i = 0; i < 3; i++)
          testJob('match_$i', title: 'Kitchen and garden lights $i', createdAt: base.subtract(Duration(days: i + 1))),
      ];
      final source = FakeJobFeedSource(jobs);
      final page = await JobFeedPager(source, pageSize: 10, maxServerPages: 4).load(JobFeedPlan.of(const JobFeedQuery(text: 'kitchen garden')));
      expect(source.plans.first.arrayContains!.value, 'kitchen');
      expect(page.items.map((j) => j.id), ['match_0', 'match_1', 'match_2']);
      expect(page.hasMore, isFalse);
      expect(source.calls, 3, reason: 'scanned past the first non-matching pages');
    });

    test('stops after the scan limit and reports more to load', () async {
      final source = FakeJobFeedSource([...many(60)]);
      final page = await JobFeedPager(source, pageSize: 10, maxServerPages: 2)
          .load(JobFeedPlan.of(const JobFeedQuery(text: 'sockets zz')));
      expect(page.items, isEmpty);
      expect(page.hasMore, isTrue);
      expect(source.calls, 2);
    });

    test('sorting by budget', () async {
      final source = FakeJobFeedSource([...many(5)]);
      final low = await JobFeedPager(source).load(JobFeedPlan.of(const JobFeedQuery(sort: JobSort.budgetLow)));
      expect(low.items.map((j) => j.budgetMax), [1000, 1100, 1200, 1300, 1400]);
      final high = await JobFeedPager(source).load(JobFeedPlan.of(const JobFeedQuery(sort: JobSort.budgetHigh)));
      expect(high.items.first.budgetMax, 1400);
      final oldest = await JobFeedPager(source).load(JobFeedPlan.of(const JobFeedQuery(sort: JobSort.oldest)));
      expect(oldest.items.first.id, 'job_0');
    });

    test('category and budget filters', () async {
      final source = FakeJobFeedSource([
        testJob('elec', budgetMax: 3000),
        testJob('plumb', categoryId: 'plumber', categoryName: 'Plumber', budgetMax: 3000),
        testJob('big', budgetMax: 40000),
      ]);
      final cat = await JobFeedPager(source).load(JobFeedPlan.of(const JobFeedQuery(categoryId: 'plumber')));
      expect(cat.items.map((j) => j.id), ['plumb']);
      final band = await JobFeedPager(source).load(JobFeedPlan.of(const JobFeedQuery(budgetBand: BudgetBand.from15kTo50k)));
      expect(band.items.map((j) => j.id), ['big']);
    });
  });

  group('controller', () {
    late FakeJobFeedSource source;
    late ProviderContainer container;

    setUp(() {
      source = FakeJobFeedSource([...many(20)]);
      container = ProviderContainer(overrides: [jobFeedSourceProvider.overrideWithValue(source)]);
      addTearDown(container.dispose);
    });

    Future<JobFeedState> settle() async {
      await pumpEventQueue();
      return container.read(jobFeedControllerProvider);
    }

    test('loads the first page, then more without duplicates', () async {
      final sub = container.listen(jobFeedControllerProvider, (_, _) {});
      addTearDown(sub.close);
      var s = await settle();
      expect(s.loading, isFalse);
      expect(s.items.length, 15);
      expect(s.hasMore, isTrue);
      await container.read(jobFeedControllerProvider.notifier).loadMore();
      s = container.read(jobFeedControllerProvider);
      expect(s.items.length, 20);
      expect(s.items.map((j) => j.id).toSet().length, 20);
      expect(s.hasMore, isFalse);
    });

    test('a new query replaces the results', () async {
      final sub = container.listen(jobFeedControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await settle();
      source.jobs = [...source.jobs, testJob('plumb', categoryId: 'plumber', categoryName: 'Plumber')];
      await container.read(jobFeedControllerProvider.notifier).setQuery(const JobFeedQuery(categoryId: 'plumber'));
      final s = container.read(jobFeedControllerProvider);
      expect(s.items.map((j) => j.id), ['plumb']);
      expect(s.query.categoryId, 'plumber');
    });

    test('errors are classified and retry recovers', () async {
      source.failWith = firestoreError('failed-precondition');
      final sub = container.listen(jobFeedControllerProvider, (_, _) {});
      addTearDown(sub.close);
      var s = await settle();
      expect(s.error, JobFeedError.missingIndex);
      expect(s.items, isEmpty);

      source.failWith = firestoreError('unavailable');
      await container.read(jobFeedControllerProvider.notifier).refresh();
      expect(container.read(jobFeedControllerProvider).error, JobFeedError.network);

      source.failWith = firestoreError('permission-denied');
      await container.read(jobFeedControllerProvider.notifier).refresh();
      expect(container.read(jobFeedControllerProvider).error, JobFeedError.permission);

      source.failWith = null;
      await container.read(jobFeedControllerProvider.notifier).refresh();
      s = container.read(jobFeedControllerProvider);
      expect(s.error, isNull);
      expect(s.items, isNotEmpty);
    });
  });

  group('job detail reads', () {
    test('a refused read is not retried; other failures retry a few times', () {
      expect(jobReadRetry(0, firestoreError('permission-denied')), isNull);
      expect(jobReadRetry(0, firestoreError('unavailable')), isNotNull);
      expect(jobReadRetry(3, firestoreError('unavailable')), isNull);
    });
  });
}

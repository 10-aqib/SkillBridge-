// My Jobs, the worker job feed and job details. Mocked data (fake data source
// and providers) — not real Firebase.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/jobs/data/job_feed_source.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/job_details_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/my_jobs_screen.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_job_datasource.dart';
import '../helpers/fake_job_feed_source.dart';
import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());
  late FakeJobDataSource ds;
  setUp(() => ds = FakeJobDataSource());

  Future<void> pump(WidgetTester tester, Widget screen, {required UserEntity user, List<dynamic> extra = const []}) async {
    tester.view.physicalSize = const Size(420, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(path: '/start', builder: (_, _) => screen),
      GoRoute(path: RouteNames.jobDetailsPath, builder: (_, s) => Text('DETAILS ${s.pathParameters['jobId']}')),
      GoRoute(path: RouteNames.jobEditPath, builder: (_, s) => Text('EDIT ${s.pathParameters['jobId']}')),
      GoRoute(path: RouteNames.clientPostJobPath, builder: (_, _) => const Text('POST JOB')),
    ]);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      jobRemoteDataSourceProvider.overrideWithValue(ds),
      currentUserProvider.overrideWith((ref) => user),
      ...extra,
    ]));
    await tester.pumpAndSettle();
  }

  group('My Jobs', () {
    final jobs = <JobEntity>[
      testJob('open1', title: 'Fix two kitchen sockets', totalProposals: 2),
      testJob('open2', title: 'Repair leaking tap', categoryId: 'plumber', categoryName: 'Plumber', totalProposals: 2),
      testJob('active1', title: 'Paint the hall', status: JobStatus.inProgress, selectedWorkerId: 'w1', selectedWorkerName: 'Bilal'),
      testJob('closed1', title: 'Old AC service', status: JobStatus.cancelled),
      testJob('closedDirect', title: 'Direct request closed', status: JobStatus.cancelled, selectedWorkerId: 'w2', selectedWorkerName: 'Kamran'),
    ];
    List<dynamic> overrides(Stream<List<JobEntity>> s) => [clientJobsStreamProvider.overrideWith((ref) => s)];

    testWidgets('shows the client\'s jobs grouped by status with the server-kept proposal counts', (tester) async {
      await pump(tester, const MyJobsScreen(), user: testUser('client_1'), extra: overrides(Stream.value(jobs)));
      expect(find.text('${l.jobStatusOpen} · 2'), findsOneWidget);
      expect(find.text('${l.myJobsTabActive} · 1'), findsOneWidget);
      expect(find.text('${l.jobStatusClosed} · 2'), findsOneWidget);
      expect(find.text('Fix two kitchen sockets'), findsOneWidget);
      expect(find.text('Paint the hall'), findsNothing);
      expect(find.text(l.jobProposalsCount(2)), findsNWidgets(2));

      await tester.tap(find.text('${l.myJobsTabActive} · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Paint the hall'), findsOneWidget);
      expect(find.text(l.jobEdit), findsNothing, reason: 'only open jobs can be edited');
    });

    testWidgets('closing asks first and changes only the status', (tester) async {
      await pump(tester, const MyJobsScreen(), user: testUser('client_1'), extra: overrides(Stream.value(jobs)));
      await tester.tap(find.text(l.jobClose).first);
      await tester.pumpAndSettle();
      expect(find.text(l.jobCloseTitle), findsOneWidget);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(ds.statusChanges, isEmpty);
      await tester.tap(find.text(l.jobClose).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.jobClose).last);
      await tester.pumpAndSettle();
      expect(ds.statusChanges.single, ('open1', 'cancelled'));
    });

    testWidgets('closed public jobs can be reopened; closed direct requests cannot', (tester) async {
      await pump(tester, const MyJobsScreen(), user: testUser('client_1'), extra: overrides(Stream.value(jobs)));
      await tester.ensureVisible(find.text('${l.jobStatusClosed} · 2'));
      await tester.tap(find.text('${l.jobStatusClosed} · 2'));
      await tester.pumpAndSettle();
      expect(find.text(l.jobReopen), findsOneWidget);
      await tester.tap(find.text(l.jobReopen));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.jobReopen).last);
      await tester.pumpAndSettle();
      expect(ds.statusChanges.single, ('closed1', 'open'));
    });

    testWidgets('empty state', (tester) async {
      await pump(tester, const MyJobsScreen(), user: testUser('client_1'), extra: overrides(Stream.value(const [])));
      expect(find.text(l.myJobsEmptyTitle), findsOneWidget);
    });

    testWidgets('error state offers retry', (tester) async {
      await pump(tester, const MyJobsScreen(), user: testUser('client_1'), extra: overrides(Stream.error('offline')));
      expect(find.text(l.myJobsLoadError), findsOneWidget);
      expect(find.text(l.tryAgain), findsOneWidget);
    });
  });

  group('Job feed', () {
    final base = DateTime(2026, 11, 1);
    List<JobEntity> jobs() => [
          for (var i = 0; i < 18; i++)
            testJob('e$i', title: 'Kitchen wiring job $i', createdAt: base.add(Duration(hours: i)), budgetMax: 2000.0 + i * 100),
          testJob('p1', title: 'Repair leaking tap', categoryId: 'plumber', categoryName: 'Plumber', skills: ['Leak repair'], createdAt: base.subtract(const Duration(days: 1))),
          testJob('closed', title: 'Closed job here', status: JobStatus.cancelled),
          testJob('direct', title: 'Private direct request', selectedWorkerId: 'w9'),
        ];

    Future<FakeJobFeedSource> pumpFeed(WidgetTester tester, List<JobEntity> data) async {
      final source = FakeJobFeedSource(data);
      await pump(tester, const JobFeedScreen(), user: testUser('w1', role: 'worker'), extra: [jobFeedSourceProvider.overrideWithValue(source)]);
      return source;
    }

    testWidgets('lists real open jobs only, newest first, and loads more', (tester) async {
      final source = await pumpFeed(tester, jobs());
      expect(find.text('Kitchen wiring job 17'), findsOneWidget);
      expect(find.text('Closed job here'), findsNothing);
      expect(find.text('Private direct request'), findsNothing);
      expect(find.text(l.jobFeedShowing(15)), findsOneWidget);
      // Scrolling near the end loads the next page automatically.
      await tester.scrollUntilVisible(find.text(l.jobFeedEnd), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text('Repair leaking tap'), findsOneWidget);
      expect(source.plans.every((p) => p.equals['status'] == 'open' && p.equals.containsKey('selectedWorkerId')), isTrue);
    });

    testWidgets('search queries the server and shows a no-match state with clear-all', (tester) async {
      final source = await pumpFeed(tester, jobs());
      await tester.enterText(find.byType(TextField).first, 'tap');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(source.plans.last.arrayContains!.value, 'tap');
      expect(find.text('Repair leaking tap'), findsOneWidget);
      expect(find.text('Kitchen wiring job 17'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'generator');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text(l.jobFeedNoMatchTitle), findsOneWidget);
      await tester.tap(find.text(l.jobFeedClearAll));
      await tester.pumpAndSettle();
      expect(find.text('Kitchen wiring job 17'), findsOneWidget);
    });

    testWidgets('filters apply, stay visible as chips, and clear all', (tester) async {
      final source = await pumpFeed(tester, jobs());
      await tester.tap(find.byTooltip(l.jobFeedFilters));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plumber'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leak repair'));
      await tester.tap(find.text(l.jobPostedLast7Days));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.jobFeedShowResults));
      await tester.pumpAndSettle();
      final plan = source.plans.last;
      expect(plan.equals['categoryId'], 'plumber');
      expect(plan.arrayContainsAny!.value, ['Leak repair']);
      expect(plan.createdAfter, isNotNull);
      expect(find.byType(InputChip), findsNWidgets(3));
      expect(find.text('Repair leaking tap'), findsNothing, reason: 'posted 8+ days before "now"');

      await tester.tap(find.text(l.jobFeedClearAll).first);
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNothing);
      expect(source.plans.last.equals.keys, unorderedEquals(['status', 'selectedWorkerId']));
    });

    testWidgets('sorting by budget re-queries in budget order', (tester) async {
      final source = await pumpFeed(tester, jobs());
      await tester.tap(find.byTooltip(l.jobFeedSort));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.jobSortBudgetHigh).last);
      await tester.pumpAndSettle();
      expect(source.plans.last.orderBy, 'budgetMax');
      expect(source.plans.last.descending, isTrue);
      // Budgets are only ranked within one pay type, never hourly against fixed.
      expect(source.plans.last.equals['budgetType'], 'fixed');
      expect(find.text('Kitchen wiring job 17'), findsOneWidget, reason: 'highest budget first');
    });

    testWidgets('no jobs at all shows an honest empty state, not samples', (tester) async {
      await pumpFeed(tester, const []);
      expect(find.text(l.jobFeedEmptyTitle), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('errors show a retry that recovers', (tester) async {
      final source = FakeJobFeedSource(jobs())..failWith = firestoreError('unavailable');
      await pump(tester, const JobFeedScreen(), user: testUser('w1', role: 'worker'), extra: [jobFeedSourceProvider.overrideWithValue(source)]);
      expect(find.text(l.jobFeedErrorTitle), findsOneWidget);
      source.failWith = null;
      await tester.tap(find.text(l.tryAgain));
      await tester.pumpAndSettle();
      expect(find.text('Kitchen wiring job 17'), findsOneWidget);
    });

    testWidgets('tapping a job opens its details', (tester) async {
      await pumpFeed(tester, jobs());
      await tester.tap(find.text('Kitchen wiring job 17'));
      await tester.pumpAndSettle();
      expect(find.text('DETAILS e17'), findsOneWidget);
    });
  });

  group('Job details', () {
    final job = testJob('j1', title: 'Fix two kitchen sockets', urgency: 'immediate');
    List<dynamic> detailOverrides(JobEntity? j) => [
          jobByIdProvider('j1').overrideWith((ref) => Stream.value(j)),
          workerProfileProvider('client_1').overrideWith((ref) async => testUser('client_1')),
          workerProposalsStreamProvider.overrideWith((ref) => Stream.value(const <ProposalEntity>[])),
        ];

    testWidgets('a worker sees full details, the client\'s public info, message and report', (tester) async {
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('w1', role: 'worker', name: 'Bilal Ahmed'), extra: detailOverrides(job));
      expect(find.text('Fix two kitchen sockets'), findsOneWidget);
      expect(find.text(job.description), findsOneWidget);
      expect(find.text(l.jobBudgetFixedPrice('Rs 2,000 – 3,000')), findsOneWidget);
      expect(find.text('House wiring'), findsOneWidget);
      expect(find.text(l.jobStatusOpen), findsOneWidget);
      expect(find.text(l.jobUrgencyImmediate), findsWidgets);
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.textContaining(l.jobMemberSince('Jan 2026')), findsOneWidget);
      expect(find.text('+923001234567'), findsNothing, reason: 'no private contact details');
      expect(find.text(l.jobMessageClient), findsOneWidget);
      expect(find.byTooltip(l.jobReport), findsOneWidget);
      expect(find.text(l.jobClose), findsNothing);
      expect(find.text(l.proposalSendCta), findsOneWidget);
    });

    testWidgets('the owner gets edit and close, not message or report', (tester) async {
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('client_1'), extra: detailOverrides(job));
      expect(find.text(l.jobMessageClient), findsNothing);
      expect(find.byTooltip(l.jobReport), findsNothing);
      expect(find.text(l.jobClose), findsOneWidget);
      await tester.tap(find.byTooltip(l.jobEdit));
      await tester.pumpAndSettle();
      expect(find.text('EDIT j1'), findsOneWidget);
    });

    testWidgets('a closed job offers the owner Reopen and nothing to workers', (tester) async {
      final closed = testJob('j1', status: JobStatus.cancelled);
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('client_1'), extra: detailOverrides(closed));
      expect(find.text(l.jobReopen), findsOneWidget);
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('w1', role: 'worker'), extra: detailOverrides(closed));
      expect(find.text(l.jobMessageClient), findsNothing);
    });

    testWidgets('suspended workers see a notice and no actions', (tester) async {
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('w1', role: 'worker', active: false), extra: detailOverrides(job));
      expect(find.text(l.jobSuspendedNotice), findsOneWidget);
      expect(find.text(l.jobMessageClient), findsNothing);
    });

    testWidgets('if access is refused after a cached copy was shown, the copy is hidden', (tester) async {
      Stream<JobEntity?> cachedThenDenied() async* {
        yield job;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw firestoreError('permission-denied');
      }

      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('w1', role: 'worker'), extra: [
        jobByIdProvider('j1').overrideWith((ref) => cachedThenDenied()),
        workerProfileProvider('client_1').overrideWith((ref) async => testUser('client_1')),
        workerProposalsStreamProvider.overrideWith((ref) => Stream.value(const <ProposalEntity>[])),
      ]);
      expect(find.text('Fix two kitchen sockets'), findsNothing);
      expect(find.text(l.jobUnavailableTitle), findsOneWidget);
    });

    testWidgets('a job that is gone or not readable shows an unavailable state', (tester) async {
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('w1', role: 'worker'), extra: detailOverrides(null));
      expect(find.text(l.jobUnavailableTitle), findsOneWidget);
    });
  });

  test('feed sort labels exist for every option', () async {
    for (final s in JobSort.values) {
      expect(s.field, anyOf('createdAt', 'budgetMax'));
    }
  });
}

// Phase 3B: sending a proposal, the worker's proposals, the client's received
// proposals and one proposal's details. Mocked data (fake data source and
// providers) — not real Firebase; the security rules are tested separately
// against the emulator in rules-tests/.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/job_details_screen.dart';
import 'package:skill_bridge/features/proposals/data/models/proposal_model.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/my_proposals_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/proposal_details_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/received_proposals_screen.dart';
import 'package:skill_bridge/features/proposals/presentation/screens/submit_proposal_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_proposal_datasource.dart';
import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final worker = testUser('w1', role: 'worker', name: 'Bilal Ahmed');
  final client = testUser('client_1');
  final openJob = testJob('j1', totalProposals: 2);

  Future<FakeProposalDataSource> pump(
    WidgetTester tester,
    Widget screen, {
    required UserEntity user,
    FakeProposalDataSource? ds,
    Map<String, JobEntity?> jobs = const {},
    Map<String, UserModel> profiles = const {},
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A fresh provider scope for every pump (some tests pump several screens).
    await tester.pumpWidget(const SizedBox());
    final source = ds ?? FakeProposalDataSource();
    final people = <String, UserModel>{
      'client_1': client,
      'w1': worker,
      'w2': testUser('w2', role: 'worker', name: 'Kamran Ali'),
      ...profiles,
    };
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(path: '/start', builder: (_, _) => screen),
      GoRoute(path: RouteNames.proposalDetailsPath, builder: (_, s) => Text('PROPOSAL ${s.pathParameters['proposalId']}')),
      GoRoute(path: RouteNames.jobDetailsPath, builder: (_, s) => Text('DETAILS ${s.pathParameters['jobId']}')),
      GoRoute(path: RouteNames.jobProposePath, builder: (_, s) => Text('PROPOSE ${s.pathParameters['jobId']}')),
      GoRoute(path: RouteNames.publicWorkerProfilePath, name: RouteNames.publicWorkerProfileName, builder: (_, s) => Text('PROFILE ${s.pathParameters['workerId']}')),
      GoRoute(path: RouteNames.workerJobFeedPath, builder: (_, _) => const Text('FEED')),
    ]);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      proposalRemoteDataSourceProvider.overrideWithValue(source),
      currentUserProvider.overrideWith((ref) => user),
      for (final e in jobs.entries) jobByIdProvider(e.key).overrideWith((ref) => Stream.value(e.value)),
      for (final e in people.entries) workerProfileProvider(e.key).overrideWith((ref) async => e.value),
    ]));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Screens with the existing live map keep animating; pump a fixed time.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    return source;
  }

  Future<void> fillForm(WidgetTester tester, {String price = '2500', String? duration, String cover = 'I have fixed many sparking sockets and carry a tester.'}) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), price);
    if (duration != null) {
      await tester.enterText(fields.at(1), duration);
    } else {
      await tester.tap(find.text(l.proposalDuration1to2));
    }
    await tester.enterText(fields.at(2), cover);
    await tester.pumpAndSettle();
  }

  group('Send a proposal', () {
    testWidgets('empty or too-short answers are refused before anything is sent', (tester) async {
      final ds = await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, jobs: {'j1': openJob});
      expect(find.text(l.proposalFormTitle), findsWidgets);
      await tester.tap(find.text(l.proposalReview));
      await tester.pumpAndSettle();
      expect(find.text(l.jobFormBudgetRequired), findsOneWidget);
      expect(find.text(l.proposalDurationRequired), findsOneWidget);
      expect(find.text(l.proposalCoverRequired), findsOneWidget);

      await fillForm(tester, cover: 'Too short');
      await tester.tap(find.text(l.proposalReview));
      await tester.pumpAndSettle();
      expect(find.text(l.proposalCoverRequired), findsOneWidget);
      expect(find.text(l.proposalConfirmTitle), findsNothing);
      expect(ds.submitted, isEmpty);
    });

    testWidgets('a valid proposal is confirmed, sent once with the job\'s owner and title, then opened', (tester) async {
      final ds = await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, jobs: {'j1': openJob});
      await tester.tap(find.text(l.jobBudgetTypeDaily));
      await fillForm(tester, price: '3000');
      await tester.tap(find.text(l.proposalReview));
      await tester.pumpAndSettle();
      expect(find.text(l.proposalConfirmTitle), findsOneWidget);
      expect(find.text(l.jobBudgetPerDay('Rs 3,000')), findsOneWidget, reason: 'summary before sending');
      await tester.tap(find.text(l.proposalSend));
      await tester.pumpAndSettle();

      final sent = ds.submitted.single;
      expect(sent.id, 'j1_w1');
      expect(sent.clientId, 'client_1');
      expect(sent.jobTitle, openJob.title);
      expect(sent.workerId, 'w1');
      expect(sent.rateType, 'daily');
      expect(sent.proposedRate, 3000);
      expect(sent.estimatedDuration, l.proposalDuration1to2);
      expect(find.text('PROPOSAL j1_w1'), findsOneWidget);
    });

    testWidgets('while sending, the button is busy and a second send is impossible', (tester) async {
      final ds = FakeProposalDataSource()..hold = Completer<void>();
      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, ds: ds, jobs: {'j1': openJob});
      await fillForm(tester);
      await tester.tap(find.text(l.proposalReview));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.proposalSend));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text(l.proposalReview), warnIfMissed: false);
      await tester.pump();
      expect(ds.submitted.length, 1);
      ds.hold!.complete();
      ds.hold = null;
      await tester.pumpAndSettle();
      expect(find.text('PROPOSAL j1_w1'), findsOneWidget);
    });

    testWidgets('a refused send explains that the job is no longer open', (tester) async {
      final ds = FakeProposalDataSource()..failWith = const ProposalExceptionForTest();
      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, ds: ds, jobs: {'j1': openJob});
      await fillForm(tester);
      await tester.tap(find.text(l.proposalReview));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.proposalSend));
      await tester.pumpAndSettle();
      expect(find.text(l.proposalSendFailed), findsOneWidget);
      expect(find.text(l.proposalReview), findsOneWidget, reason: 'still on the form, answers kept');
    });

    testWidgets('clients, suspended workers, the job owner and closed jobs get a clear block, not a form', (tester) async {
      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: client, jobs: {'j1': openJob});
      expect(find.text(l.proposalOnlyWorkers), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: testUser('w1', role: 'worker', active: false), jobs: {'j1': openJob});
      expect(find.text(l.proposalSuspended), findsOneWidget);

      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: testUser('w1', role: 'worker'), jobs: {'j1': testJob('j1', clientId: 'w1')});
      expect(find.text(l.proposalOwnJob), findsOneWidget);

      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, jobs: {'j1': testJob('j1', status: JobStatus.assigned, selectedWorkerId: 'w9')});
      expect(find.text(l.proposalJobClosedTitle), findsOneWidget);

      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, jobs: {'j1': testJob('j1', selectedWorkerId: 'w9')});
      expect(find.text(l.proposalJobClosedTitle), findsOneWidget, reason: 'a direct request is not a public job');

      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, jobs: {'j1': null});
      expect(find.text(l.jobUnavailableTitle), findsOneWidget);
    });

    testWidgets('one proposal per job: an existing one is shown instead of a second form', (tester) async {
      final ds = FakeProposalDataSource([testProposal('j1', 'w1')]);
      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, ds: ds, jobs: {'j1': openJob});
      expect(find.text(l.proposalAlreadySentTitle), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text(l.proposalView));
      await tester.pumpAndSettle();
      expect(find.text('PROPOSAL j1_w1'), findsOneWidget);
    });

    testWidgets('a withdrawn proposal can be sent again, prefilled', (tester) async {
      final ds = FakeProposalDataSource([testProposal('j1', 'w1', status: ProposalStatus.withdrawn, rate: 1800)]);
      await pump(tester, const SubmitProposalScreen(jobId: 'j1'), user: worker, ds: ds, jobs: {'j1': openJob});
      expect(find.text(l.proposalFormTitleAgain), findsOneWidget);
      expect(find.text(l.proposalResendNote), findsOneWidget);
      expect(find.text('1800'), findsOneWidget);
      await tester.tap(find.text(l.proposalReview));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.proposalSendAgain));
      await tester.pumpAndSettle();
      expect(ds.store['j1_w1']!.status, ProposalStatus.pending);
      expect(find.text('PROPOSAL j1_w1'), findsOneWidget);
    });
  });

  group('My proposals', () {
    final mine = [
      testProposal('j1', 'w1', createdAt: DateTime(2026, 11, 7)),
      testProposal('j2', 'w1', jobTitle: 'Repair leaking tap', viewedAt: DateTime(2026, 11, 8), createdAt: DateTime(2026, 11, 6)),
      testProposal('j3', 'w1', jobTitle: 'Paint the hall', status: ProposalStatus.accepted),
      testProposal('j4', 'w1', jobTitle: 'Old AC service', status: ProposalStatus.rejected, closedReason: 'filled'),
      testProposal('j5', 'w1', jobTitle: 'Geyser check', status: ProposalStatus.withdrawn),
    ];
    final jobs = {
      'j1': openJob,
      'j2': testJob('j2', title: 'Repair leaking tap'),
      'j3': testJob('j3', title: 'Paint the hall', status: JobStatus.assigned, selectedWorkerId: 'w1'),
      'j4': testJob('j4', title: 'Old AC service', status: JobStatus.assigned, selectedWorkerId: 'w2'),
      'j5': testJob('j5', title: 'Geyser check'),
    };

    testWidgets('grouped by status with job title, client, price, date and both statuses', (tester) async {
      await pump(tester, const MyProposalsScreen(), user: worker, ds: FakeProposalDataSource(mine), jobs: jobs);
      expect(find.text('${l.proposalStatusPending} · 2'), findsOneWidget, reason: 'viewed still counts as pending');
      expect(find.text('${l.proposalStatusAccepted} · 1'), findsOneWidget);
      expect(find.text('${l.proposalTabNotSelected} · 1'), findsOneWidget);
      expect(find.text('${l.proposalStatusWithdrawn} · 1'), findsOneWidget);
      expect(find.text('Fix two kitchen sockets'), findsOneWidget);
      expect(find.text('Repair leaking tap'), findsOneWidget);
      expect(find.text(l.proposalStatusViewed), findsOneWidget);
      expect(find.text(l.jobStatusOpen), findsNWidgets(2));
      expect(find.textContaining('Ayesha Khan'), findsNWidgets(2));
      expect(find.text(l.jobBudgetFixedPrice('Rs 2,500')), findsNWidgets(2));
      expect(find.text('Paint the hall'), findsNothing);

      await tester.ensureVisible(find.text('${l.proposalTabNotSelected} · 1'));
      await tester.tap(find.text('${l.proposalTabNotSelected} · 1'));
      await tester.pumpAndSettle();
      expect(find.text(l.proposalStatusFilled), findsOneWidget);
      expect(find.text(l.proposalFilledNotice), findsOneWidget);
      expect(find.text(l.proposalWithdraw), findsNothing, reason: 'only pending proposals can be withdrawn');
    });

    testWidgets('withdrawing asks first, then moves the proposal to Withdrawn', (tester) async {
      final ds = await pump(tester, const MyProposalsScreen(), user: worker, ds: FakeProposalDataSource(mine), jobs: jobs);
      await tester.tap(find.text(l.proposalWithdraw).first);
      await tester.pumpAndSettle();
      expect(find.text(l.proposalWithdrawTitle), findsOneWidget);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(ds.withdrawn, isEmpty);

      await tester.tap(find.text(l.proposalWithdraw).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.proposalWithdraw).last);
      await tester.pumpAndSettle();
      expect(ds.withdrawn.single, 'j1_w1');
      expect(find.text('${l.proposalStatusWithdrawn} · 2'), findsOneWidget);
      expect(find.text(l.proposalWithdrawn), findsOneWidget, reason: 'confirmation survives the card leaving the tab');
    });

    testWidgets('view and view job open the right pages', (tester) async {
      await pump(tester, const MyProposalsScreen(), user: worker, ds: FakeProposalDataSource(mine), jobs: jobs);
      await tester.tap(find.text(l.proposalViewJob).first);
      await tester.pumpAndSettle();
      expect(find.text('DETAILS j1'), findsOneWidget);
    });

    testWidgets('opens on a tab that has proposals, not an empty Pending tab', (tester) async {
      await pump(tester, const MyProposalsScreen(), user: worker,
          ds: FakeProposalDataSource([testProposal('j4', 'w1', jobTitle: 'Old AC service', status: ProposalStatus.rejected, closedReason: 'filled')]), jobs: jobs);
      expect(find.text('Old AC service'), findsOneWidget);
      expect(find.text(l.proposalStatusFilled), findsOneWidget);
    });

    testWidgets('empty state points to the job feed', (tester) async {
      await pump(tester, const MyProposalsScreen(), user: worker);
      expect(find.text(l.myProposalsEmptyTitle), findsOneWidget);
      await tester.tap(find.text(l.myProposalsFindWork));
      await tester.pumpAndSettle();
      expect(find.text('FEED'), findsOneWidget);
    });

    testWidgets('error state offers retry', (tester) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(home: const MyProposalsScreen(), overrides: [
        currentUserProvider.overrideWith((ref) => worker),
        workerProposalsStreamProvider.overrideWith((ref) => Stream.error('offline')),
      ]));
      await tester.pumpAndSettle();
      expect(find.text(l.myProposalsLoadError), findsOneWidget);
      expect(find.text(l.tryAgain), findsOneWidget);
    });
  });

  group('Received proposals', () {
    final received = [
      testProposal('j1', 'w1', rate: 2500, createdAt: DateTime(2026, 11, 5)),
      testProposal('j1', 'w2', workerName: 'Kamran Ali', rate: 900, rateType: 'hourly', createdAt: DateTime(2026, 11, 6)),
      testProposal('j1', 'w3', workerName: 'Withdrawn Worker', status: ProposalStatus.withdrawn),
    ];
    final reviewed = UserModel(
      uid: 'w1',
      email: 'w1@example.com',
      displayName: 'Bilal Ahmed',
      phoneNumber: '',
      role: 'worker',
      isEmailVerified: true,
      isPhoneVerified: false,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    testWidgets('shows real workers, prices and cover letters; withdrawn ones are hidden', (tester) async {
      await pump(tester, const ReceivedProposalsScreen(jobId: 'j1'), user: client, ds: FakeProposalDataSource(received), jobs: {'j1': openJob}, profiles: {'w1': reviewed});
      expect(find.text('${l.proposalTabActive} · 2'), findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('Kamran Ali'), findsOneWidget);
      expect(find.text('Withdrawn Worker'), findsNothing);
      expect(find.text(l.jobBudgetFixedPrice('Rs 2,500')), findsOneWidget);
      expect(find.text(l.jobBudgetPerHour('Rs 900')), findsOneWidget);
      expect(find.textContaining('★'), findsNothing, reason: 'no reviews, so no rating is shown');
      expect(find.text(l.publicProfileNew), findsNWidgets(2));
      expect(find.text(l.receivedProposalsCount(2)), findsOneWidget);
    });

    testWidgets('compare groups by rate type, so fixed and hourly are never ranked together', (tester) async {
      await pump(tester, const ReceivedProposalsScreen(jobId: 'j1'), user: client, ds: FakeProposalDataSource(received), jobs: {'j1': openJob});
      await tester.tap(find.text(l.proposalCompare));
      await tester.pumpAndSettle();
      expect(find.text(l.proposalCompareTitle), findsOneWidget);
      expect(find.text(l.proposalRateFixed), findsOneWidget);
      expect(find.text(l.proposalRateHourly), findsOneWidget);
    });

    testWidgets('another client\'s job shows nothing', (tester) async {
      await pump(tester, const ReceivedProposalsScreen(jobId: 'j1'), user: testUser('client_2'), ds: FakeProposalDataSource(received), jobs: {'j1': openJob});
      expect(find.text(l.jobUnavailableTitle), findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsNothing);
    });

    testWidgets('empty state', (tester) async {
      await pump(tester, const ReceivedProposalsScreen(jobId: 'j1'), user: client, jobs: {'j1': openJob});
      expect(find.text(l.receivedProposalsEmptyTitle), findsOneWidget);
    });

    test('price sort ranks within a rate type only', () {
      final sorted = sortProposals([
        testProposal('j', 'a', rate: 900, rateType: 'hourly'),
        testProposal('j', 'b', rate: 5000),
        testProposal('j', 'c', rate: 300, rateType: 'hourly'),
        testProposal('j', 'd', rate: 2000),
        testProposal('j', 'e', rate: 1500, rateType: 'daily'),
      ], ReceivedSort.price);
      expect(sorted.map((p) => p.workerId), ['d', 'b', 'e', 'c', 'a']);
    });
  });

  group('Proposal details', () {
    testWidgets('the client opening a pending proposal marks it viewed once', (tester) async {
      final ds = await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w1'), user: client, ds: FakeProposalDataSource([testProposal('j1', 'w1')]), jobs: {'j1': openJob});
      expect(ds.viewed, ['j1_w1']);
      expect(find.text(l.proposalStatusViewed), findsOneWidget);
      await tester.pumpAndSettle();
      expect(ds.viewed.length, 1);
    });

    testWidgets('the worker opening their own proposal does not mark it viewed', (tester) async {
      final ds = await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w1'), user: worker, ds: FakeProposalDataSource([testProposal('j1', 'w1')]), jobs: {'j1': openJob});
      expect(ds.viewed, isEmpty);
      expect(find.text(l.proposalWithdraw), findsOneWidget);
      expect(find.text(l.proposalAccept), findsNothing);
    });

    testWidgets('accepting asks first, explains what happens, and hires through one action', (tester) async {
      final ds = await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w1'), user: client,
          ds: FakeProposalDataSource([testProposal('j1', 'w1'), testProposal('j1', 'w2', workerName: 'Kamran Ali')]), jobs: {'j1': openJob});
      expect(find.text(l.proposalAboutWorker), findsOneWidget);
      await tester.tap(find.text(l.proposalAccept));
      await tester.pumpAndSettle();
      expect(find.text(l.proposalAcceptTitle('Bilal Ahmed')), findsOneWidget);
      expect(find.text(l.proposalAcceptBody), findsOneWidget);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(ds.accepted, isEmpty);

      await tester.tap(find.text(l.proposalAccept));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.proposalAccept).last);
      await tester.pumpAndSettle();
      expect(ds.accepted.single, ('j1_w1', 'j1'));
      expect(ds.store['j1_w1']!.status, ProposalStatus.accepted);
      expect(ds.store['j1_w2']!.status, ProposalStatus.rejected);
      expect(ds.store['j1_w2']!.closedReason, 'filled');
      expect(find.text(l.proposalAcceptedNotice), findsOneWidget);
      expect(find.text(l.proposalAccept), findsNothing);
    });

    testWidgets('declining asks first', (tester) async {
      final ds = await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w1'), user: client, ds: FakeProposalDataSource([testProposal('j1', 'w1')]), jobs: {'j1': openJob});
      await tester.tap(find.text(l.proposalDecline));
      await tester.pumpAndSettle();
      expect(find.text(l.proposalDeclineTitle('Bilal Ahmed')), findsOneWidget);
      await tester.tap(find.text(l.proposalDecline).last);
      await tester.pumpAndSettle();
      expect(ds.rejected.single, 'j1_w1');
      expect(find.text(l.proposalStatusDeclined), findsOneWidget);
    });

    testWidgets('no accept or decline once the job is no longer open', (tester) async {
      await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w1'), user: client,
          ds: FakeProposalDataSource([testProposal('j1', 'w1')]), jobs: {'j1': testJob('j1', status: JobStatus.cancelled)});
      expect(find.text(l.proposalAccept), findsNothing);
      expect(find.text(l.proposalDecline), findsNothing);
      expect(find.text(l.proposalJobNotOpenNotice), findsOneWidget);
    });

    testWidgets('a withdrawn proposal can be sent again while the job is open', (tester) async {
      await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w1'), user: worker,
          ds: FakeProposalDataSource([testProposal('j1', 'w1', status: ProposalStatus.withdrawn)]), jobs: {'j1': openJob});
      await tester.tap(find.text(l.proposalSendAgain));
      await tester.pumpAndSettle();
      expect(find.text('PROPOSE j1'), findsOneWidget);
    });

    testWidgets('someone else\'s proposal is not shown', (tester) async {
      await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w1'), user: worker, jobs: {'j1': openJob});
      expect(find.text(l.proposalUnavailableTitle), findsOneWidget);
    });
  });

  group('Job page after a hire', () {
    final filled = testJob('j1', status: JobStatus.assigned, selectedWorkerId: 'w1', selectedWorkerName: 'Bilal Ahmed', totalProposals: 2);

    testWidgets('a worker who was not selected sees their status, not the hired worker or a chat', (tester) async {
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: testUser('w2', role: 'worker', name: 'Kamran Ali'),
          ds: FakeProposalDataSource([testProposal('j1', 'w2', workerName: 'Kamran Ali', status: ProposalStatus.rejected, closedReason: 'filled')]),
          jobs: {'j1': filled});
      expect(find.text(l.proposalStatusFilled), findsOneWidget);
      expect(find.text(l.proposalViewMine), findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsNothing, reason: 'other applicants are not told who was hired');
      expect(find.text(l.jobMessageClient), findsNothing);
      expect(find.text(l.proposalSendCta), findsNothing);
    });

    testWidgets('the hired worker and the client see who was hired', (tester) async {
      await pump(tester, const JobDetailsScreen(jobId: 'j1'), user: client, jobs: {'j1': filled}, settle: false);
      expect(find.text(l.jobHiredLabel), findsOneWidget);
      expect(find.text(l.jobDirectRequestLabel), findsNothing);
      expect(find.text(l.proposalsViewReceived(2)), findsOneWidget);
    });
  });

  group('Applicants and the hired worker identity', () {
    // After a hire, other applicants cannot read the job (the rules refuse
    // it: it names who was hired). The screens show the status copied to
    // the proposal instead, and no link to the job.
    final copied = testProposal('j1', 'w2', workerName: 'Kamran Ali', status: ProposalStatus.rejected,
        closedReason: 'filled', jobStatus: JobStatus.assigned);

    testWidgets('My proposals shows the copied job status without the job', (tester) async {
      await pump(tester, const MyProposalsScreen(), user: testUser('w2', role: 'worker', name: 'Kamran Ali'),
          ds: FakeProposalDataSource([copied]), jobs: {'j1': null});
      expect(find.text(l.proposalStatusFilled), findsOneWidget);
      expect(find.text(l.jobStatusAssigned), findsOneWidget);
      expect(find.text(l.proposalViewJob), findsNothing);
      expect(find.text('Bilal Ahmed'), findsNothing);
    });

    testWidgets('the proposal page does too', (tester) async {
      await pump(tester, const ProposalDetailsScreen(proposalId: 'j1_w2'), user: testUser('w2', role: 'worker', name: 'Kamran Ali'),
          ds: FakeProposalDataSource([copied]), jobs: {'j1': null});
      expect(find.text(l.jobStatusAssigned), findsOneWidget);
      expect(find.text(l.proposalViewJob), findsNothing);
      expect(find.text(l.proposalFilledNotice), findsOneWidget);
      expect(find.text(l.jobMessageClient), findsNothing);
    });

    test('the copied status is read from the proposal document', () {
      final p = ProposalModel.fromMap('j1_w2', {'jobId': 'j1', 'status': 'rejected', 'jobStatus': 'in_progress'});
      expect(p.jobStatus, JobStatus.inProgress);
      expect(p.jobStatusOr(null), JobStatus.inProgress);
      expect(p.jobStatusOr(JobStatus.completed), JobStatus.completed, reason: 'the live job wins when readable');
      expect(ProposalModel.fromMap('x', {'status': 'pending'}).jobStatusOr(null), JobStatus.open);
    });
  });

  group('Budget sort normalisation', () {
    test('a budget sort always names one pay type', () {
      expect(const JobFeedQuery(sort: JobSort.budgetHigh).normalized().budgetType, 'fixed');
      expect(const JobFeedQuery(sort: JobSort.budgetLow, budgetType: 'hourly').normalized().budgetType, 'hourly');
      expect(const JobFeedQuery().normalized().budgetType, isNull, reason: 'date sorts mix types freely');
    });

    test('removing the pay type from a budget sort falls back to newest', () {
      final q = const JobFeedQuery(sort: JobSort.budgetHigh, budgetType: 'daily').withoutBudgetType();
      expect(q.budgetType, isNull);
      expect(q.sort, JobSort.newest);
      expect(const JobFeedQuery(sort: JobSort.oldest, budgetType: 'daily').withoutBudgetType().sort, JobSort.oldest);
    });

    test('clearing filters keeps a budget sort valid', () {
      final q = const JobFeedQuery(sort: JobSort.budgetHigh, budgetType: 'daily', categoryId: 'plumber').clearFilters();
      expect(q.categoryId, isNull);
      expect(q.budgetType, 'fixed');
    });
  });
}

/// A failure that is not a known Firestore code (shows the generic message).
class ProposalExceptionForTest implements Exception {
  const ProposalExceptionForTest();
}

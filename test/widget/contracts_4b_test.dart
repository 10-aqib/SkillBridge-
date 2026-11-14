// Phase 4B: work coordination (progress updates, revision, submission
// history, completion) and contract-scoped live location. Mocked data (fake
// data source, actions, location source and sink) — not real Firebase. The
// server rules for all of this run against the emulator in rules-tests/, the
// trusted functions in functions/test/.
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_activity.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_model.dart';
import 'package:skill_bridge/features/contracts/data/models/live_location.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/contract_details_screen.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_lifecycle_actions.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_contracts.dart';
import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

/// Location UI tests drive the controller's state directly.
class FakeLiveController extends LiveLocationController {
  FakeLiveController(this.next, [LocationSource? source]) : super(source);
  LiveShareStatus next;
  final List<String> calls = [];

  @override
  LiveShareState build() => const LiveShareState();

  @override
  Future<LiveShareStatus> start(String contractId) async {
    calls.add('start:$contractId');
    state = LiveShareState(contractId: contractId, status: next, lastSentAt: next == LiveShareStatus.sharing ? DateTime.now() : null);
    return next;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    state = const LiveShareState();
  }
}

class FakeSource implements LocationSource {
  LocationAccess access = LocationAccess.granted;
  bool settingsAvailable = true;
  GeoFix first = const GeoFix(lat: 31.52, lng: 74.35, accuracy: 12.0);
  final fixes = StreamController<GeoFix>.broadcast();
  final List<String> opened = [];

  @override
  Future<LocationAccess> checkAccess() async => access;
  @override
  Future<LocationAccess> ensureAccess() async => access;
  @override
  Future<bool> isPrecise() async => true;
  @override
  Future<GeoFix> current({Duration timeLimit = const Duration(seconds: 20), LocationProfile profile = LocationProfile.sharing}) async => first;
  @override
  Stream<GeoFix> watch([LocationProfile profile = LocationProfile.sharing]) => fixes.stream;
  @override
  Stream<bool> serviceEnabledChanges() => const Stream.empty();
  @override
  bool get canOpenSettings => settingsAvailable;
  @override
  Future<bool> openAppSettings() async {
    opened.add('app');
    return true;
  }
  @override
  Future<bool> openLocationSettings() async {
    opened.add('gps');
    return true;
  }
}

class FakeSink implements LiveLocationSink {
  final List<String> writes = [];
  Object? updateError;

  @override
  Future<void> start(String contractId, String workerId, GeoFix fix) async => writes.add('start:$contractId:$workerId:${fix.lat}');
  @override
  Future<void> update(String contractId, GeoFix fix) async {
    if (updateError != null) throw updateError!;
    writes.add('update:$contractId:${fix.lat}');
  }

  @override
  Future<void> remove(String contractId) async => writes.add('remove:$contractId');
}

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final client = testUser('client_1');
  final worker = testUser('w1', role: 'worker', name: 'Bilal Ahmed');
  final started = DateTime(2026, 11, 10, 9);
  final submitted = DateTime(2026, 11, 10, 15);

  ContractModel m(Map<String, dynamic> d) => ContractModel.fromMap('k', d);

  group('Stage with revisions (same rule as the server)', () {
    test('submitted while submissions outnumber revision requests; sent back is in progress', () {
      expect(m(contractDoc(started: started, submitted: submitted)).stage, ContractStage.submitted, reason: 'Phase 4A contract, no counters');
      final back = m(contractDoc(started: started, submitted: submitted, extra: {'submissionCount': 1, 'revisionCount': 1, 'revisionNote': 'Fix the plate'}));
      expect(back.stage, ContractStage.inProgress);
      expect(back.awaitingResubmission, isTrue);
      expect(back.canCancel, isTrue);
      final again = m(contractDoc(started: started, submitted: submitted, extra: {'submissionCount': 2, 'revisionCount': 1}));
      expect(again.stage, ContractStage.submitted);
      expect(again.revisionsLeft, 2);
      expect(m(contractDoc(started: started, submitted: submitted, extra: {'submissionCount': 4, 'revisionCount': 3})).revisionsLeft, 0);
    });
  });

  Future<(FakeContractStore, FakeContractActions)> pump(
    WidgetTester tester, {
    required UserEntity user,
    required Map<String, dynamic> contract,
    FakeLiveController? live,
    Stream<LiveLocation?>? location,
    void Function(FakeContractStore, FakeContractActions)? setup,
  }) async {
    tester.view.physicalSize = const Size(420, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    final store = FakeContractStore({'k': contract});
    final actions = FakeContractActions(store);
    setup?.call(store, actions);
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(path: '/start', builder: (_, _) => const ContractDetailsScreen(contractId: 'k')),
      GoRoute(path: RouteNames.contractSubmitPath, builder: (_, s) => Text('SUBMIT ${s.pathParameters['contractId']}')),
      GoRoute(path: RouteNames.jobDetailsPath, builder: (_, s) => Text('DETAILS ${s.pathParameters['jobId']}')),
      GoRoute(path: RouteNames.writeReviewPath, name: RouteNames.writeReviewName, builder: (_, s) => Text('REVIEW ${s.pathParameters['contractId']}')),
      GoRoute(path: RouteNames.publicWorkerProfilePath, name: RouteNames.publicWorkerProfileName, builder: (_, s) => const Text('PROFILE')),
    ]);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      contractRemoteDataSourceProvider.overrideWithValue(store),
      contractActionsProvider.overrideWithValue(actions),
      currentUserProvider.overrideWith((ref) => user),
      workerProfileProvider('client_1').overrideWith((ref) async => client),
      workerProfileProvider('w1').overrideWith((ref) async => worker),
      connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
      liveLocationControllerProvider.overrideWith(() => live ?? FakeLiveController(LiveShareStatus.sharing)),
      contractLiveLocationProvider('k').overrideWith((ref) => location ?? Stream.value(null)),
    ]));
    await tester.pumpAndSettle();
    return (store, actions);
  }

  group('Revision (client sends work back)', () {
    testWidgets('the client asks for changes with a note; the work goes back to the worker', (tester) async {
      final (store, actions) = await pump(tester, user: client, contract: contractDoc(started: started, submitted: submitted));
      expect(find.text(l.contractRevisionsLeft(3)), findsOneWidget);
      await tester.tap(find.text(l.contractRequestChanges));
      await tester.pumpAndSettle();
      expect(find.text(l.contractRevisionTitle), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'too short');
      await tester.tap(find.text(l.contractRevisionSend));
      await tester.pumpAndSettle();
      expect(find.text(l.contractRevisionNoteTooShort), findsOneWidget);
      expect(actions.calls.where((c) => c.startsWith('revision')), isEmpty);
      await tester.enterText(find.byType(TextFormField), 'The left socket cover is loose.');
      await tester.tap(find.text(l.contractRevisionSend));
      await tester.pumpAndSettle();
      expect(actions.calls, contains('revision:k:The left socket cover is loose.'));
      expect(store.data['k']!['revisionCount'], 1);
      expect(find.text(l.contractRevisionBannerClient('Bilal Ahmed')), findsOneWidget);
      expect(find.text(l.contractConfirm), findsNothing, reason: 'nothing to confirm until resubmitted');
    });

    testWidgets('no rounds left: no "Ask for changes", and the client is told what they can do', (tester) async {
      await pump(tester, user: client, contract: contractDoc(started: started, submitted: submitted, extra: {'submissionCount': 4, 'revisionCount': 3}));
      expect(find.text(l.contractRequestChanges), findsNothing);
      expect(find.text(l.contractNoRevisionsLeft('Bilal Ahmed')), findsOneWidget);
      expect(find.text(l.contractConfirm), findsOneWidget);
    });

    testWidgets('the worker sees what to change and resubmits', (tester) async {
      await pump(tester,
          user: worker,
          contract: contractDoc(started: started, submitted: submitted, extra: {'submissionCount': 1, 'revisionCount': 1, 'revisionNote': 'The left socket cover is loose.'}));
      expect(find.text(l.contractRevisionBannerWorker('Ayesha Khan', 'The left socket cover is loose.')), findsOneWidget);
      await tester.tap(find.text(l.contractResubmit));
      await tester.pumpAndSettle();
      expect(find.text('SUBMIT k'), findsOneWidget);
    });

    testWidgets('earlier submissions and the changes asked for are kept and shown', (tester) async {
      await pump(tester,
          user: client,
          contract: contractDoc(started: started, submitted: submitted, extra: {'submissionCount': 2, 'revisionCount': 1}),
          setup: (store, _) => store.submissions['k'] = [
                ContractSubmission(number: 1, note: 'First go at it.', attachments: const [], submittedAt: started, revisionNote: 'Fix the plate', revisionRequestedAt: submitted),
                ContractSubmission(number: 2, note: 'Both sockets replaced and tested.', attachments: const [], submittedAt: submitted),
              ]);
      expect(find.text(l.contractSubmissionHistory), findsOneWidget);
      expect(find.text(l.contractSubmissionN(1)), findsOneWidget);
      expect(find.text(l.contractSubmissionN(2)), findsOneWidget, reason: 'the current one is numbered too');
      expect(find.text('First go at it.'), findsOneWidget);
      expect(find.text(l.contractSubmissionChangesRequested('Fix the plate')), findsOneWidget);
      expect(find.text(l.contractEventRevision), findsOneWidget, reason: 'in the history');
      expect(find.text(l.contractEventResubmitted(2)), findsOneWidget);
    });
  });

  group('Progress updates', () {
    testWidgets('the worker posts an update; a retry of the same note reuses its id', (tester) async {
      final (store, actions) = await pump(tester, user: worker, contract: contractDoc(started: started));
      actions.failWith = FirebaseException(plugin: 'cloud_functions', code: 'unavailable');
      await tester.tap(find.text(l.contractPostUpdate).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Parts bought, wiring tomorrow.');
      await tester.tap(find.text(l.contractUpdatePost));
      await tester.pumpAndSettle();
      expect(store.updates['k'] ?? [], isEmpty);
      actions.failWith = null;
      await tester.tap(find.text(l.contractPostUpdate).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Parts bought, wiring tomorrow.');
      await tester.tap(find.text(l.contractUpdatePost));
      await tester.pumpAndSettle();
      expect(actions.requestIds, ['req_test_1', 'req_test_1'], reason: 'same note, same id: saved once');
      expect(store.updates['k'], hasLength(1));
      expect(find.text('Parts bought, wiring tomorrow.'), findsWidgets);
      // A different note is a new update.
      await tester.tap(find.text(l.contractPostUpdate).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Done with the kitchen.');
      await tester.tap(find.text(l.contractUpdatePost));
      await tester.pumpAndSettle();
      expect(actions.requestIds.last, 'req_test_2');
    });

    testWidgets('the client sees the updates, or that there are none yet', (tester) async {
      await pump(tester, user: client, contract: contractDoc(started: started));
      expect(find.text(l.contractUpdatesEmptyClient('Bilal Ahmed')), findsOneWidget);
      expect(find.text(l.contractPostUpdate), findsNothing, reason: 'only the worker posts');
      await pump(tester,
          user: client,
          contract: contractDoc(started: started),
          setup: (store, _) => store.updates['k'] = [ContractUpdate(id: 'u1', note: 'On my way', authorId: 'w1', createdAt: started)]);
      expect(find.text('On my way'), findsWidgets);
    });
  });

  group('Where things stand and completion', () {
    testWidgets('the steps show progress; a submitted worker is told it was received', (tester) async {
      await pump(tester, user: worker, contract: contractDoc(started: started, submitted: submitted));
      for (final s in [l.contractStepHired, l.contractStepStarted, l.contractStepSubmitted, l.contractStepConfirmed]) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text(l.contractWorkerSubmittedNotice('Nov 10, 2026', 'Ayesha Khan')), findsOneWidget);
      expect(find.text(l.contractConfirm), findsNothing, reason: 'the worker can never confirm');
    });

    testWidgets('after completion the worker sees the client confirmed; no payment claims', (tester) async {
      final done = contractDoc(status: 'completed', started: started, submitted: submitted, extra: {'completedAt': Timestamp.fromDate(submitted)});
      await pump(tester, user: worker, contract: done);
      expect(find.text(l.contractClientConfirmedNotice('Ayesha Khan', 'Nov 10, 2026')), findsOneWidget);
      expect(find.textContaining('Paid'), findsNothing);
      expect(find.textContaining('EasyPaisa'), findsNothing);
      expect(find.text(l.contractPaymentNote), findsOneWidget, reason: 'payment stays outside the app');
      await pump(tester, user: client, contract: done);
      expect(find.text(l.contractClientCompletedNotice('Nov 10, 2026')), findsOneWidget);
      expect(find.text(l.contractWriteReview), findsOneWidget);
    });

    testWidgets('evidence photos are read with the party\'s access (bytes), not shareable links', (tester) async {
      final (_, actions) = await pump(tester,
          user: client,
          contract: contractDoc(started: started, submitted: submitted, extra: {
            'submission': {'note': 'Done.', 'attachments': ['contracts/k/evidence/1.jpg']},
          }),
          setup: (_, a) => a.evidence = base64Decode(_png));
      expect(actions.evidenceReads, ['contracts/k/evidence/1.jpg']);
      expect(find.bySemanticsLabel(l.contractEvidencePhoto(1)), findsOneWidget);
    });

    testWidgets('a completed job page has no payment button or "paid" wording', (tester) async {
      final job = testJob('j1', status: JobStatus.completed, selectedWorkerId: 'w1');
      await tester.pumpWidget(testApp(home: Scaffold(body: JobLifecycleActions(job: job)), overrides: [
        currentUserProvider.overrideWith((ref) => client),
        contractRemoteDataSourceProvider.overrideWithValue(FakeContractStore()),
      ]));
      await tester.pumpAndSettle();
      expect(find.textContaining('EasyPaisa'), findsNothing);
      expect(find.textContaining('Paid'), findsNothing);
      expect(find.text('Job completed'), findsOneWidget);
    });
  });

  group('Live location (contract-scoped, with consent)', () {
    testWidgets('the worker must agree before sharing starts, and can stop', (tester) async {
      final live = FakeLiveController(LiveShareStatus.sharing);
      await pump(tester, user: worker, contract: contractDoc(started: started), live: live);
      expect(find.text(l.liveWorkerIntro('Ayesha Khan')), findsOneWidget);
      await tester.tap(find.text(l.liveStartSharing));
      await tester.pumpAndSettle();
      expect(find.text(l.liveConsentTitle), findsOneWidget);
      await tester.tap(find.text(l.liveNotNow));
      await tester.pumpAndSettle();
      expect(live.calls, isEmpty, reason: 'nothing starts without consent');
      await tester.tap(find.text(l.liveStartSharing));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.liveConsentAgree));
      await tester.pumpAndSettle();
      expect(live.calls, ['start:k']);
      expect(find.text(l.liveStopSharing), findsOneWidget);
      await tester.tap(find.text(l.liveStopSharing));
      await tester.pumpAndSettle();
      expect(live.calls.last, 'stop');
    });

    for (final (status, text) in [
      (LiveShareStatus.permissionDenied, 'permission'),
      (LiveShareStatus.permissionBlocked, 'blocked'),
      (LiveShareStatus.serviceOff, 'gps'),
      (LiveShareStatus.ended, 'ended'),
    ]) {
      testWidgets('device and server states are explained ($text)', (tester) async {
        await pump(tester, user: worker, contract: contractDoc(started: started), live: FakeLiveController(status));
        await tester.tap(find.text(l.liveStartSharing));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.liveConsentAgree));
        await tester.pumpAndSettle();
        final expected = switch (status) {
          LiveShareStatus.permissionDenied => l.livePermissionDenied,
          LiveShareStatus.permissionBlocked => l.livePermissionBlocked,
          LiveShareStatus.serviceOff => l.liveServiceOff,
          _ => l.liveEnded,
        };
        expect(find.text(expected), findsOneWidget);
        if (status == LiveShareStatus.permissionBlocked || status == LiveShareStatus.serviceOff) {
          expect(find.text(l.liveOpenSettings), findsOneWidget);
        }
      });
    }

    testWidgets("where settings can't be opened (a browser), no 'Open settings' button is offered", (tester) async {
      final web = FakeSource()..settingsAvailable = false;
      await pump(tester, user: worker, contract: contractDoc(started: started), live: FakeLiveController(LiveShareStatus.permissionBlocked, web));
      await tester.tap(find.text(l.liveStartSharing));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.liveConsentAgree));
      await tester.pumpAndSettle();
      expect(find.text(l.livePermissionBlocked), findsOneWidget);
      expect(find.text(l.liveOpenSettings), findsNothing);
    });

    testWidgets('the client sees "not sharing", a live position, or a stale one never labelled live', (tester) async {
      await pump(tester, user: client, contract: contractDoc(started: started));
      expect(find.text(l.liveClientNotSharing('Bilal Ahmed')), findsOneWidget);

      final fresh = LiveLocation(lat: 31.52, lng: 74.35, accuracy: 12, updatedAt: DateTime.now().subtract(const Duration(seconds: 20)));
      await pump(tester, user: client, contract: contractDoc(started: started), location: Stream.value(fresh));
      expect(find.text(l.liveBadge), findsOneWidget);
      expect(find.text(l.liveOpenInMaps), findsOneWidget, reason: 'text + link to a maps app');
      expect(find.text(l.trackOpen), findsOneWidget, reason: 'Navigation phase 9: full-screen live map');
      expect(find.text(l.liveAccuracy(12)), findsOneWidget);

      final stale = LiveLocation(lat: 31.52, lng: 74.35, updatedAt: DateTime.now().subtract(const Duration(minutes: 5)));
      await pump(tester, user: client, contract: contractDoc(started: started), location: Stream.value(stale));
      expect(find.text(l.liveBadge), findsNothing);
      expect(find.text(l.liveBadgeStale), findsOneWidget);
      expect(find.text(l.liveClientStale('Bilal Ahmed')), findsOneWidget);
    });

    testWidgets('no location section once the work is submitted', (tester) async {
      await pump(tester, user: client, contract: contractDoc(started: started, submitted: submitted));
      expect(find.text(l.liveSectionTitle), findsNothing);
      await pump(tester, user: worker, contract: contractDoc(started: started, submitted: submitted));
      expect(find.text(l.liveStartSharing), findsNothing);
    });
  });

  group('Live location controller', () {
    late FakeSource source;
    late FakeSink sink;
    late ProviderContainer container;
    late StreamController<UserEntity?> userChanges;

    setUp(() {
      source = FakeSource();
      sink = FakeSink();
      userChanges = StreamController<UserEntity?>.broadcast();
      container = ProviderContainer(overrides: [
        liveLocationSinkProvider.overrideWithValue(sink),
        liveLocationControllerProvider.overrideWith(() => LiveLocationController(source, Duration.zero)),
        locationSourceProvider.overrideWithValue(source),
        currentUserProvider.overrideWith((ref) => worker),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
      ]);
      container.read(connectivityStatusProvider);
    });
    tearDown(() {
      container.dispose();
      userChanges.close();
    });

    LiveLocationController ctl() => container.read(liveLocationControllerProvider.notifier);
    LiveShareState st() => container.read(liveLocationControllerProvider);

    test('starts on the contract document as the signed-in worker, then sends new fixes', () async {
      await Future<void>.delayed(Duration.zero);
      expect(await ctl().start('k'), LiveShareStatus.sharing);
      expect(sink.writes, ['start:k:w1:31.52']);
      source.fixes.add(const GeoFix(lat: 31.6, lng: 74.4, accuracy: 8.0));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sink.writes.last, 'update:k:31.6');
      expect(st().sharingFor('k'), isTrue);
    });

    test('denied permission or GPS off writes nothing', () async {
      source.access = LocationAccess.denied;
      expect(await ctl().start('k'), LiveShareStatus.permissionDenied);
      source.access = LocationAccess.serviceOff;
      expect(await ctl().start('k'), LiveShareStatus.serviceOff);
      expect(sink.writes, isEmpty);
    });

    test('a refused write (work submitted / contract closed) ends sharing by itself', () async {
      await ctl().start('k');
      sink.updateError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      source.fixes.add(const GeoFix(lat: 31.6, lng: 74.4, accuracy: 8.0));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(st().status, LiveShareStatus.ended);
      sink.updateError = null;
      source.fixes.add(const GeoFix(lat: 31.7, lng: 74.5, accuracy: 8.0));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sink.writes.where((w) => w.startsWith('update')), isEmpty, reason: 'stream cancelled');
    });

    test('stopping removes the position; closing the contract stops the device too', () async {
      await ctl().start('k');
      await ctl().stop();
      expect(sink.writes.last, 'remove:k');
      expect(st().status, LiveShareStatus.idle);
      await ctl().start('k');
      ctl().contractClosed('k');
      expect(st().status, LiveShareStatus.ended);
    });

    test('offline fixes are skipped so an old position is never stamped as new', () async {
      final offline = ProviderContainer(overrides: [
        liveLocationSinkProvider.overrideWithValue(sink),
        liveLocationControllerProvider.overrideWith(() => LiveLocationController(source, Duration.zero)),
        locationSourceProvider.overrideWithValue(source),
        currentUserProvider.overrideWith((ref) => worker),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(false)),
      ]);
      addTearDown(offline.dispose);
      offline.listen(connectivityStatusProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await offline.read(liveLocationControllerProvider.notifier).start('k');
      source.fixes.add(const GeoFix(lat: 31.6, lng: 74.4, accuracy: 8.0));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sink.writes.where((w) => w.startsWith('update')), isEmpty);
    });
    test('an old cached fix is never written as current (Navigation phase 4)', () async {
      source.first = GeoFix(lat: 31.52, lng: 74.35, accuracy: 12, takenAt: DateTime.now().subtract(const Duration(minutes: 10)));
      expect(await ctl().start('k'), LiveShareStatus.error, reason: 'the only fix is 10 minutes old');
      expect(sink.writes, isEmpty);

      source.first = const GeoFix(lat: 31.52, lng: 74.35, accuracy: 12);
      await ctl().start('k');
      source.fixes.add(GeoFix(lat: 31.6, lng: 74.4, accuracy: 8, takenAt: DateTime.now().subtract(const Duration(minutes: 5))));
      source.fixes.add(const GeoFix(lat: double.nan, lng: 74.4, accuracy: 8));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sink.writes.where((w) => w.startsWith('update')), isEmpty, reason: 'old and invalid fixes are skipped');
      source.fixes.add(GeoFix(lat: 31.6, lng: 74.4, accuracy: 8, takenAt: DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sink.writes.last, 'update:k:31.6');
    });
  });
}

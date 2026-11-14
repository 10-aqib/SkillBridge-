import 'package:cloud_firestore/cloud_firestore.dart';
// Phase 4A: contracts dashboard, details, work lifecycle and submission.
// Mocked data (fake data source and actions) — not real Firebase. The trusted
// functions and rules are tested in functions/test and rules-tests/.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_model.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/contract_details_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/my_contracts_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/screens/submit_work_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/direct_request_actions.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_contracts.dart';
import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final client = testUser('client_1');
  final worker = testUser('w1', role: 'worker', name: 'Bilal Ahmed');
  final started = DateTime(2026, 11, 10, 9);
  final submitted = DateTime(2026, 11, 10, 15);

  Future<(FakeContractStore, FakeContractActions)> pump(
    WidgetTester tester,
    Widget screen, {
    required UserEntity user,
    Map<String, Map<String, dynamic>> contracts = const {},
  }) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    final store = FakeContractStore(contracts);
    final actions = FakeContractActions(store);
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(path: '/start', builder: (_, _) => screen),
      GoRoute(path: RouteNames.contractDetailsPath, builder: (_, s) => Text('CONTRACT ${s.pathParameters['contractId']}')),
      GoRoute(path: RouteNames.contractSubmitPath, builder: (_, s) => Text('SUBMIT ${s.pathParameters['contractId']}')),
      GoRoute(path: RouteNames.jobDetailsPath, builder: (_, s) => Text('DETAILS ${s.pathParameters['jobId']}')),
      GoRoute(path: RouteNames.publicWorkerProfilePath, name: RouteNames.publicWorkerProfileName, builder: (_, s) => Text('PROFILE ${s.pathParameters['workerId']}')),
      GoRoute(path: RouteNames.writeReviewPath, name: RouteNames.writeReviewName, builder: (_, s) => Text('REVIEW ${s.pathParameters['contractId']}')),
    ]);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      contractRemoteDataSourceProvider.overrideWithValue(store),
      contractActionsProvider.overrideWithValue(actions),
      currentUserProvider.overrideWith((ref) => user),
      workerProfileProvider('client_1').overrideWith((ref) async => client),
      workerProfileProvider('w1').overrideWith((ref) async => worker),
      workerProfileProvider('c9').overrideWith((ref) async => testUser('c9', name: 'Usman Tariq')),
    ]));
    await tester.pumpAndSettle();
    return (store, actions);
  }

  group('Contract stage (from stored timestamps)', () {
    test('status and timestamps decide the stage; nothing is guessed', () {
      ContractModel m(Map<String, dynamic> d) => ContractModel.fromMap('k', d);
      expect(m(contractDoc()).stage, ContractStage.notStarted);
      expect(m(contractDoc(started: started)).stage, ContractStage.inProgress);
      expect(m(contractDoc(started: started, submitted: submitted)).stage, ContractStage.submitted);
      expect(m(contractDoc(status: 'completed')).stage, ContractStage.completed);
      expect(m(contractDoc(status: 'pending', proposalId: 'direct_hire')).stage, ContractStage.requested);
      expect(m(contractDoc(status: 'rejected')).stage, ContractStage.declined);
      expect(m(contractDoc(status: 'cancelled')).stage, ContractStage.cancelled);
      expect(m(contractDoc(started: started, submitted: submitted)).canCancel, isFalse, reason: 'submitted work is confirmed, not cancelled');
    });
  });

  group('Contracts dashboard', () {
    final mixed = {
      'k1': contractDoc(started: started),
      'k2': contractDoc(jobId: 'j2', proposalId: 'j2_w1', started: started, submitted: submitted, extra: {'jobTitle': 'Install a ceiling fan'}),
      'k3': contractDoc(jobId: 'j3', proposalId: 'j3_w1', status: 'completed', extra: {'jobTitle': 'Paint the hall'}),
      'k4': contractDoc(jobId: 'j4', proposalId: 'direct_hire', status: 'pending', extra: {'jobTitle': 'Direct Hire: Electrician'}),
      'k5': contractDoc(jobId: 'j5', proposalId: 'j5_w1', status: 'cancelled', extra: {'jobTitle': 'Old AC service', 'cancelReason': 'no_longer_needed'}),
      'other': contractDoc(clientId: 'c9', jobId: 'j9', proposalId: 'j9_w2', workerId: 'w2', extra: {'jobTitle': 'Someone else\'s job'}),
    };

    testWidgets('a client sees their own contracts by tab with the worker, price, date and stage', (tester) async {
      await pump(tester, const MyContractsScreen(), user: client, contracts: mixed);
      expect(find.text('${l.contractsTabRequests} · 1'), findsOneWidget);
      expect(find.text('${l.contractsTabActive} · 2'), findsOneWidget);
      expect(find.text('${l.contractsTabCompleted} · 1'), findsOneWidget);
      expect(find.text('${l.contractsTabCancelled} · 1'), findsOneWidget);
      expect(find.text('Fix two kitchen sockets'), findsOneWidget);
      expect(find.text('Install a ceiling fan'), findsOneWidget);
      expect(find.text('Someone else\'s job'), findsNothing);
      expect(find.text(l.contractStageInProgress), findsOneWidget);
      expect(find.text(l.contractStageSubmitted), findsOneWidget);
      expect(find.text(l.contractNextClientSubmitted), findsOneWidget, reason: 'the client is told to review');
      expect(find.text('Bilal Ahmed'), findsNWidgets(2));
      expect(find.text(l.jobBudgetFixedPrice('Rs 2,500')), findsNWidgets(2));
      expect(find.text(l.contractCreatedOn('Nov 9, 2026')), findsNWidgets(2));
    });

    testWidgets('a worker sees the booking request and what to do next', (tester) async {
      await pump(tester, const MyContractsScreen(), user: worker, contracts: mixed);
      await tester.tap(find.text('${l.contractsTabRequests} · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Direct Hire: Electrician'), findsOneWidget);
      expect(find.text(l.contractNextWorkerRequested), findsOneWidget);
      expect(find.text('Ayesha Khan'), findsOneWidget, reason: 'the client\'s public name');
    });

    testWidgets('opens on a tab that has contracts', (tester) async {
      await pump(tester, const MyContractsScreen(), user: client, contracts: {'k3': mixed['k3']!});
      expect(find.text('Paint the hall'), findsOneWidget);
    });

    testWidgets('empty and error states', (tester) async {
      await pump(tester, const MyContractsScreen(), user: client);
      expect(find.text(l.contractsEmptyTitle), findsOneWidget);
      expect(find.text(l.contractsEmptyClient), findsOneWidget);

      tester.view.physicalSize = const Size(420, 2600);
      await tester.pumpWidget(const SizedBox());
      final store = FakeContractStore()..failWith = Exception('offline');
      await tester.pumpWidget(testApp(home: const MyContractsScreen(), overrides: [
        contractRemoteDataSourceProvider.overrideWithValue(store),
        currentUserProvider.overrideWith((ref) => client),
      ]));
      await tester.pumpAndSettle();
      expect(find.text(l.contractsLoadError), findsOneWidget);
      expect(find.text(l.tryAgain), findsOneWidget);
    });

    testWidgets('tapping a card opens the contract', (tester) async {
      await pump(tester, const MyContractsScreen(), user: client, contracts: {'k1': mixed['k1']!});
      await tester.tap(find.text('Fix two kitchen sockets'));
      await tester.pumpAndSettle();
      expect(find.text('CONTRACT k1'), findsOneWidget);
    });
  });

  group('Contract details and the work lifecycle', () {
    testWidgets('overview, the worker\'s public profile and a real history', (tester) async {
      await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: client, contracts: {'k1': contractDoc()});
      expect(find.text('Fix two kitchen sockets'), findsOneWidget);
      expect(find.text('Two sockets spark when plugged in.'), findsOneWidget);
      expect(find.text(l.jobBudgetFixedPrice('Rs 2,500')), findsOneWidget);
      expect(find.text('1–2 days'), findsOneWidget);
      expect(find.text('Gulberg III, Lahore'), findsOneWidget);
      expect(find.text(l.contractYourWorker), findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text(l.contractEventProposalAccepted), findsOneWidget);
      expect(find.text(l.contractEventCreated), findsOneWidget);
      expect(find.text(l.contractEventStarted), findsNothing, reason: 'not started: no invented events');
      expect(find.text(l.contractNextClientNotStarted), findsOneWidget);
      expect(find.text(l.contractStart), findsNothing, reason: 'only the worker starts');
      expect(find.text(l.contractConfirm), findsNothing);
      expect(find.text(l.contractPaymentNote), findsOneWidget);
    });

    testWidgets('5. the hired worker starts work after confirming', (tester) async {
      final (store, actions) = await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: worker, contracts: {'k1': contractDoc()});
      expect(find.text(l.contractYourClient), findsOneWidget);
      await tester.tap(find.text(l.contractStart));
      await tester.pumpAndSettle();
      expect(find.text(l.contractStartTitle), findsOneWidget);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(actions.calls, isEmpty);
      await tester.tap(find.text(l.contractStart));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractStart).last);
      await tester.pumpAndSettle();
      expect(actions.calls, ['start:k1']);
      expect(find.text(l.contractStageInProgress), findsOneWidget);
      // The confirmation snackbar and the history entry read the same.
      expect(find.text(l.contractEventStarted), findsWidgets);
      expect(find.text(l.contractSubmit), findsOneWidget, reason: 'next step: submit');
      expect(store.data['k1']!['workStartedAt'], isNotNull);
    });

    testWidgets('6. submitting opens the submission screen (worker only)', (tester) async {
      await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: worker, contracts: {'k1': contractDoc(started: started)});
      await tester.tap(find.text(l.contractSubmit));
      await tester.pumpAndSettle();
      expect(find.text('SUBMIT k1'), findsOneWidget);
    });

    testWidgets('7. the client reviews the submitted work and confirms completion', (tester) async {
      final (_, actions) = await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: client,
          contracts: {'k1': contractDoc(started: started, submitted: submitted)});
      expect(find.text(l.contractReviewWork), findsOneWidget);
      expect(find.text('Both sockets replaced and tested.'), findsOneWidget);
      expect(find.text(l.contractCancel), findsNothing, reason: 'submitted work is confirmed, not cancelled');
      await tester.tap(find.text(l.contractConfirm));
      await tester.pumpAndSettle();
      expect(find.text(l.contractConfirmTitle), findsOneWidget);
      await tester.tap(find.text(l.contractConfirm).last);
      await tester.pumpAndSettle();
      expect(actions.calls, ['confirm:k1']);
      // Phase 4B: the success state names the confirmation date.
      expect(find.text(l.contractClientCompletedNotice('Nov 10, 2026')), findsOneWidget);
      expect(find.text(l.contractEventCompleted), findsOneWidget);
      expect(find.text(l.contractWriteReview), findsOneWidget);
    });

    testWidgets('8. the worker never gets a confirm action on their own work', (tester) async {
      await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: worker,
          contracts: {'k1': contractDoc(started: started, submitted: submitted)});
      expect(find.text(l.contractConfirm), findsNothing);
      // Phase 4B: a clear "submitted" confirmation for the worker.
      expect(find.text(l.contractWorkerSubmittedNotice('Nov 10, 2026', 'Ayesha Khan')), findsOneWidget);
    });

    testWidgets('booking requests: the worker accepts or declines', (tester) async {
      final (_, actions) = await pump(tester, const ContractDetailsScreen(contractId: 'k4'), user: worker,
          contracts: {'k4': contractDoc(status: 'pending', proposalId: 'direct_hire')});
      expect(find.text(l.contractEventRequested), findsOneWidget);
      await tester.tap(find.text(l.contractRequestAccept));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractRequestAccept).last);
      await tester.pumpAndSettle();
      expect(actions.calls, ['respond:k4:true']);
      expect(find.text(l.contractStart), findsOneWidget);
    });

    testWidgets('cancelling needs a reason and confirmation, and is recorded', (tester) async {
      final (_, actions) = await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: client, contracts: {'k1': contractDoc()});
      await tester.ensureVisible(find.text(l.contractCancel));
      await tester.tap(find.text(l.contractCancel));
      await tester.pumpAndSettle();
      expect(find.text(l.contractCancelTitle), findsOneWidget);
      await tester.tap(find.text(l.contractCancel).last);
      await tester.pumpAndSettle();
      expect(actions.calls, isEmpty, reason: 'no reason chosen');
      await tester.tap(find.text(l.contractCancelReasonNotNeeded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractCancel).last);
      await tester.pumpAndSettle();
      expect(actions.calls, ['cancel:k1:no_longer_needed']);
      expect(find.text(l.contractCancelledNotice(l.contractRoleClient, l.contractCancelReasonNotNeeded)), findsOneWidget);
    });

    testWidgets('the client shares the exact address privately; the worker sees it', (tester) async {
      final (_, actions) = await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: client, contracts: {'k1': contractDoc()});
      await tester.tap(find.text(l.contractShareAddress));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'House 5, Street 2, Gulberg III');
      await tester.tap(find.text(l.contractShareAddressAction));
      await tester.pumpAndSettle();
      expect(actions.calls, ['address:k1:House 5, Street 2, Gulberg III']);
      expect(find.text('House 5, Street 2, Gulberg III'), findsOneWidget);

      await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: worker,
          contracts: {'k1': contractDoc(extra: {'serviceAddress': 'House 5, Street 2, Gulberg III'})});
      expect(find.text('House 5, Street 2, Gulberg III'), findsOneWidget);
      expect(find.text(l.contractShareAddress), findsNothing);
    });

    testWidgets('Navigation phase 8: the map pin shows on the contract; the worker sees when it is missing', (tester) async {
      const address = 'House 5, Street 2, Gulberg III';
      await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: worker,
          contracts: {'k1': contractDoc(extra: {'serviceAddress': address})});
      expect(find.text(l.contractPinMissing), findsOneWidget);

      await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: worker,
          contracts: {'k1': contractDoc(extra: {'serviceAddress': address, 'serviceLocation': const GeoPoint(31.5204, 74.3587)})});
      expect(find.text(l.contractPinSet), findsOneWidget);
      expect(find.text(l.contractPinMissing), findsNothing);
    });

    testWidgets('the client can remove a pin from the address sheet (sent as a clear, not as a new pin)', (tester) async {
      const address = 'House 5, Street 2, Gulberg III';
      final (store, actions) = await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: client,
          contracts: {'k1': contractDoc(extra: {'serviceAddress': address, 'serviceLocation': const GeoPoint(31.5204, 74.3587)})});
      expect(find.text(l.contractPinSet), findsOneWidget);
      await tester.tap(find.text(l.contractUpdateAddress));
      await tester.pumpAndSettle();
      expect(find.text(l.contractPinHelp), findsOneWidget);
      expect(find.text('31.52040, 74.35870'), findsOneWidget);
      await tester.tap(find.text(l.contractPinRemove));
      await tester.pumpAndSettle();
      expect(find.text(l.contractPinAdd), findsOneWidget);
      await tester.tap(find.text(l.contractShareAddressAction));
      await tester.pumpAndSettle();
      expect(actions.calls.last, 'address:k1:$address', reason: 'no new pin sent');
      expect(find.text(l.contractPinSet), findsNothing, reason: 'cleared');
    });

    testWidgets('updating only the address text keeps an existing pin untouched', (tester) async {
      final (_, actions) = await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: client,
          contracts: {'k1': contractDoc(extra: {'serviceAddress': 'House 5, Street 2', 'serviceLocation': const GeoPoint(31.5204, 74.3587)})});
      await tester.tap(find.text(l.contractUpdateAddress));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'House 5-A, Street 2, Gulberg III');
      await tester.tap(find.text(l.contractShareAddressAction));
      await tester.pumpAndSettle();
      expect(actions.calls.last, 'address:k1:House 5-A, Street 2, Gulberg III');
      expect(find.text(l.contractPinSet), findsOneWidget, reason: 'pin kept');
    });

    testWidgets('a refused action explains itself and changes nothing', (tester) async {
      final store = FakeContractStore({'k1': contractDoc()});
      tester.view.physicalSize = const Size(420, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final actions = FakeContractActions(store)..failWith = Exception('boom');
      await tester.pumpWidget(testApp(home: const ContractDetailsScreen(contractId: 'k1'), overrides: [
        contractRemoteDataSourceProvider.overrideWithValue(store),
        contractActionsProvider.overrideWithValue(actions),
        currentUserProvider.overrideWith((ref) => worker),
        workerProfileProvider('client_1').overrideWith((ref) async => client),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractStart));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractStart).last);
      await tester.pumpAndSettle();
      expect(find.text(l.contractActionFailed), findsOneWidget);
      expect(store.data['k1']!['workStartedAt'], isNull);
    });

    testWidgets('someone who is not a participant gets no actions', (tester) async {
      await pump(tester, const ContractDetailsScreen(contractId: 'k1'), user: testUser('c9', name: 'Usman Tariq'), contracts: {'k1': contractDoc()});
      for (final label in [l.contractStart, l.contractSubmit, l.contractConfirm, l.contractCancel, l.contractShareAddress]) {
        expect(find.text(label), findsNothing);
      }
    });
  });

  group('Direct requests', () {
    testWidgets('the requested worker accepts after confirming, and the contract opens', (tester) async {
      final (_, actions) = await pump(tester, const Scaffold(body: DirectRequestActions(jobId: 'd1', jobTitle: 'Fix the geyser')), user: worker);
      await tester.tap(find.text(l.contractRequestAccept));
      await tester.pumpAndSettle();
      expect(find.text(l.contractDirectAcceptTitle), findsOneWidget);
      await tester.tap(find.text(l.contractRequestAccept).last);
      await tester.pumpAndSettle();
      expect(actions.calls, ['direct:d1:true']);
      expect(find.text('CONTRACT d1_w1'), findsOneWidget);
    });

    testWidgets('declining asks first', (tester) async {
      final (_, actions) = await pump(tester, const Scaffold(body: DirectRequestActions(jobId: 'd1', jobTitle: 'Fix the geyser')), user: worker);
      await tester.tap(find.text(l.contractRequestDecline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(actions.calls, isEmpty);
      await tester.tap(find.text(l.contractRequestDecline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractRequestDecline).last);
      await tester.pumpAndSettle();
      expect(actions.calls, ['direct:d1:false']);
    });

    testWidgets('a contract from a direct request shows the budget range and its real history', (tester) async {
      await pump(tester, const ContractDetailsScreen(contractId: 'd1_w1'), user: client,
          contracts: {'d1_w1': contractDoc(jobId: 'd1', proposalId: 'direct_request', extra: {'agreedRate': 2500, 'priceMin': 1500})});
      expect(find.text(l.jobBudgetFixedPrice('Rs 1,500 – 2,500')), findsOneWidget);
      expect(find.text(l.contractEventDirectAccepted), findsOneWidget);
      expect(find.text(l.contractEventProposalAccepted), findsNothing);
    });
  });

  group('Submit work', () {
    testWidgets('6. a note is required; photos upload first, then the work is submitted once', (tester) async {
      Future<({Uint8List bytes, String contentType})?> picker() async {
        // A real 1×1 PNG (the preview decodes it).
        return (bytes: base64Decode(_png), contentType: 'image/png');
      }

      final (store, actions) = await pump(tester, SubmitWorkScreen(contractId: 'k1', picker: picker), user: worker,
          contracts: {'k1': contractDoc(started: started)});
      await tester.tap(find.text(l.contractSubmitReview));
      await tester.pumpAndSettle();
      expect(find.text(l.contractSubmitNoteRequired), findsOneWidget);
      expect(actions.calls, isEmpty);

      await tester.enterText(find.byType(TextField).first, 'Replaced both sockets and tested the circuit.');
      await tester.tap(find.text(l.contractAddPhoto));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractAddPhoto));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(2));
      await tester.tap(find.text(l.contractSubmitReview));
      await tester.pumpAndSettle();
      expect(find.text(l.contractSubmitTitle), findsWidgets);
      await tester.tap(find.text(l.contractSubmit).last);
      await tester.pumpAndSettle();
      expect(actions.uploads.length, 2);
      expect(actions.calls, ['submit:k1:Replaced both sockets and tested the circuit.:contracts/k1/evidence/1.jpg,contracts/k1/evidence/2.jpg']);
      expect(store.data['k1']!['submittedAt'], isNotNull);
      expect(find.text('CONTRACT k1'), findsOneWidget, reason: 'back to the contract');
    });

    testWidgets('only the hired worker, only while the work is in progress', (tester) async {
      await pump(tester, const SubmitWorkScreen(contractId: 'k1'), user: client, contracts: {'k1': contractDoc(started: started)});
      expect(find.text(l.contractOnlyWorkerSubmits), findsOneWidget);
      await pump(tester, const SubmitWorkScreen(contractId: 'k1'), user: worker, contracts: {'k1': contractDoc()});
      expect(find.text(l.contractStartFirst), findsOneWidget);
      await pump(tester, const SubmitWorkScreen(contractId: 'k1'), user: worker, contracts: {'k1': contractDoc(started: started, submitted: submitted)});
      expect(find.text(l.contractAlreadySubmitted), findsOneWidget);
    });
  });
}

// Job posting form. Mocked data source — not real Firebase (the security
// rules for jobs are tested against the emulator in rules-tests/).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/post_job_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

import '../helpers/fake_job_datasource.dart';
import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());
  late FakeJobDataSource ds;
  setUp(() => ds = FakeJobDataSource());

  Future<void> pump(WidgetTester tester, Widget screen, {UserEntity? user}) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(
        path: '/start',
        builder: (_, _) => Builder(builder: (c) => TextButton(onPressed: () => c.push('/form'), child: const Text('open'))),
      ),
      GoRoute(path: '/form', builder: (_, _) => screen),
      GoRoute(path: RouteNames.jobDetailsPath, builder: (_, s) => Text('DETAILS ${s.pathParameters['jobId']}')),
      GoRoute(path: RouteNames.clientJobsPath, builder: (_, _) => const Text('MY JOBS')),
    ]);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      jobRemoteDataSourceProvider.overrideWithValue(ds),
      currentUserProvider.overrideWith((ref) => user ?? testUser('client_1')),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // Form order: title, description, custom skill, amount, up to, area.
  Finder input(int i) => find.byType(TextFormField).at(i);

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(input(0), 'Fix two kitchen sockets');
    await tester.tap(find.text('Electrician'));
    await tester.pumpAndSettle();
    await tester.enterText(input(1),
        'Two sockets spark when plugged in. Please bring a tester and spare sockets.');
    await tester.tap(find.text('House wiring'));
    await tester.enterText(input(3), '2000');
    await tester.enterText(input(4), '3500');
    await tester.pumpAndSettle();
  }

  testWidgets('required fields are validated and nothing is sent', (tester) async {
    await pump(tester, const PostJobScreen(), user: testUser('client_1', city: ''));
    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    expect(find.text(l.jobFormTitleRequired), findsOneWidget);
    expect(find.text(l.jobFormCategoryRequired), findsOneWidget);
    expect(find.text(l.jobFormDescriptionRequired), findsOneWidget);
    expect(find.text(l.jobFormBudgetRequired), findsOneWidget);
    expect(find.text(l.jobFormCityRequired), findsOneWidget);
    expect(ds.created, isEmpty);
  });

  testWidgets('"up to" below the first amount is rejected', (tester) async {
    await pump(tester, const PostJobScreen());
    await fillValid(tester);
    await tester.enterText(input(4), '500');
    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    expect(find.text(l.jobFormBudgetMaxInvalid), findsOneWidget);
    expect(ds.created, isEmpty);
  });

  testWidgets('publishing asks first, then saves a real job for the signed-in client', (tester) async {
    await pump(tester, const PostJobScreen());
    await fillValid(tester);
    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    expect(find.text(l.jobConfirmTitle), findsOneWidget);
    expect(find.text(l.jobBudgetFixedPrice('Rs 2,000 – 3,500')), findsOneWidget, reason: 'summary shown');

    await tester.tap(find.text(l.jobConfirmKeepEditing));
    await tester.pumpAndSettle();
    expect(ds.created, isEmpty, reason: 'cancel publishes nothing');

    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.jobConfirmPublish));
    await tester.pumpAndSettle();

    final job = ds.created.single;
    expect(job.clientId, 'client_1');
    expect(job.clientName, 'Ayesha Khan');
    expect(job.status, JobStatus.open);
    expect(job.selectedWorkerId, isNull);
    expect(job.totalProposals, 0);
    expect(job.categoryId, 'electrician');
    expect(job.requiredSkills, ['House wiring']);
    expect((job.budgetMin, job.budgetMax, job.budgetType), (2000, 3500, 'fixed'));
    expect(job.city, 'Lahore');
    expect(find.text('DETAILS new_job_1'), findsOneWidget);
  });

  testWidgets('cannot publish twice while saving', (tester) async {
    ds.gate = Completer<void>();
    await pump(tester, const PostJobScreen());
    await fillValid(tester);
    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.jobConfirmPublish));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final submit = tester.widget<SbButton>(find.byType(SbButton).last);
    expect(submit.isLoading, isTrue);
    expect(submit.onPressed, isNull, reason: 'disabled while saving');
    await tester.tap(find.byType(SbButton).last, warnIfMissed: false);
    await tester.pump();
    expect(find.text(l.jobConfirmTitle), findsNothing, reason: 'no second confirmation');
    ds.gate!.complete();
    await tester.pumpAndSettle();
    expect(ds.created.length, 1);
  });

  testWidgets('a failed publish keeps the form and explains', (tester) async {
    ds.fail = true;
    await pump(tester, const PostJobScreen());
    await fillValid(tester);
    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.jobConfirmPublish));
    await tester.pumpAndSettle();
    expect(find.text(l.jobPublishFailed), findsOneWidget);
    expect(find.text(l.jobFormTitleNew), findsOneWidget);
  });

  testWidgets('worker accounts cannot post', (tester) async {
    await pump(tester, const PostJobScreen(), user: testUser('w1', role: 'worker'));
    await fillValid(tester);
    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.jobConfirmPublish));
    await tester.pumpAndSettle();
    expect(find.text(l.jobNotClient), findsOneWidget);
    expect(ds.created, isEmpty);
  });

  testWidgets('a direct request goes only to the chosen worker', (tester) async {
    await pump(tester, const PostJobScreen(workerId: 'w7', workerName: 'Bilal'));
    expect(find.text(l.jobFormDirectNote('Bilal')), findsOneWidget);
    await fillValid(tester);
    await tester.tap(find.text(l.jobFormReview));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.jobConfirmSend));
    await tester.pumpAndSettle();
    expect(ds.created.single.selectedWorkerId, 'w7');
  });

  testWidgets('editing prefills the job and saves content only', (tester) async {
    final original = testJob('j9', title: 'Paint two bedrooms', categoryId: 'painter', categoryName: 'Painter', skills: ['Wall paint'], budgetMin: 15000, budgetMax: 20000);
    await pump(tester, PostJobScreen(editJob: original));
    expect(find.text('Paint two bedrooms'), findsOneWidget);
    expect(find.text(l.jobFormTitleEdit), findsOneWidget);
    await tester.enterText(input(0), 'Paint two bedrooms and hall');
    await tester.tap(find.text(l.jobFormSaveChanges));
    await tester.pumpAndSettle();
    final saved = ds.edited.single;
    expect(saved.id, 'j9');
    expect(saved.title, 'Paint two bedrooms and hall');
    expect(saved.clientId, original.clientId);
    expect(saved.budgetMax, 20000);
    expect(ds.created, isEmpty);
    expect(find.text('open'), findsOneWidget, reason: 'returned to the previous screen');
  });
}

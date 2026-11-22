import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/data/saved_jobs_repository.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/screens/saved_jobs_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

// Saved jobs (Phase G6).

class _Store implements SavedJobsStore {
  final removed = <String>[];
  final saved = <String>[];
  @override
  Stream<List<SavedJob>> watch(String uid) => const Stream.empty();
  @override
  Future<void> save(String uid, JobEntity job) async => saved.add(job.id);
  @override
  Future<void> remove(String uid, String jobId) async => removed.add(jobId);
}

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  Future<_Store> open(WidgetTester tester, List<SavedJob> jobs) async {
    final store = _Store();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const SavedJobsScreen()),
      GoRoute(path: '/jobs/:id', builder: (_, s) => Text('JOB ${s.pathParameters['id']}')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      currentUserProvider.overrideWith((ref) => testUser('w1', role: 'worker')),
      savedJobsStoreProvider.overrideWithValue(store),
      savedJobsProvider.overrideWith((ref) => Stream.value(jobs)),
    ]));
    await tester.pumpAndSettle();
    return store;
  }

  test('a saved entry reads its snapshot safely', () {
    final j = SavedJob.fromMap('j1', {'title': 'Paint a room', 'city': 'Lahore', 'budgetMin': 1000, 'budgetMax': 'oops'});
    expect(j.jobId, 'j1');
    expect(j.title, 'Paint a room');
    expect(j.budgetMax, isNull);
    expect(SavedJob.fromMap('j2', {}).title, '');
  });

  testWidgets('empty: explains how to save', (tester) async {
    await open(tester, []);
    expect(find.text(l.savedJobsEmptyTitle), findsOneWidget);
    expect(find.text(l.savedJobsEmptyBody), findsOneWidget);
  });

  testWidgets('lists saved jobs; tap opens the job; the bookmark button removes it', (tester) async {
    final store = await open(tester, const [
      SavedJob(jobId: 'j1', title: 'Paint a room', city: 'Lahore', budgetMin: 1000, budgetMax: 2000),
      SavedJob(jobId: 'j2', title: 'Fix sockets'),
    ]);
    expect(find.text('Paint a room'), findsOneWidget);
    expect(find.textContaining('Lahore'), findsOneWidget);
    await tester.tap(find.byTooltip(l.jobBookmarkRemove).first);
    await tester.pumpAndSettle();
    expect(store.removed, ['j1']);
    await tester.tap(find.text('Fix sockets'));
    await tester.pumpAndSettle();
    expect(find.text('JOB j2'), findsOneWidget);
    expect(RouteNames.workerSavedJobsPath, '/worker/saved-jobs');
  });
}

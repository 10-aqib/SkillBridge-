import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_profile_setup_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/test_app.dart';

/// Records every profile update (mocked repository — not real Firebase).
class RecordingAuthRepository implements AuthRepository {
  final updates = <Map<String, dynamic>>[];
  bool fail = false;

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    if (fail) return const Left(ServerFailure('PERMISSION_DENIED'));
    updates.add(data);
    return Right(UserModel(
      uid: uid, email: 'worker@example.com', displayName: 'Worker', phoneNumber: '+923001234567',
      role: 'worker', isEmailVerified: true, isPhoneVerified: true, isActive: true,
      createdAt: DateTime(2026), updatedAt: DateTime(2026),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final newWorker = UserModel(
    uid: 'worker_1', email: 'worker@example.com', displayName: 'Test Worker', phoneNumber: '+923001234567',
    role: 'worker', isEmailVerified: true, isPhoneVerified: true, isActive: true,
    createdAt: DateTime(2026), updatedAt: DateTime(2026),
  );

  final verifiedWorker = UserModel(
    uid: 'worker_2', email: 'v@example.com', displayName: 'Verified Worker', phoneNumber: '+923001234567',
    role: 'worker', isEmailVerified: true, isPhoneVerified: true, isActive: true,
    createdAt: DateTime(2026), updatedAt: DateTime(2026),
    workerProfile: const WorkerProfileEntity(
      headline: 'Senior electrician', bio: 'Thirty characters of real bio text here.', categoryId: 'electrician',
      categoryName: 'Electrician', city: 'Lahore', skills: ['House wiring'], experience: 9, hourlyRate: 800,
      isVerified: true, averageRating: 4.8, totalReviews: 37, totalJobsCompleted: 41, totalEarnings: 120000,
      verificationStatus: 'verified',
    ),
  );

  late bool navigatedHome;

  Future<RecordingAuthRepository> pump(WidgetTester tester, UserEntity user, {int? step}) async {
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    navigatedHome = false;
    final repo = RecordingAuthRepository();
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(
        path: '/start',
        builder: (_, _) => Builder(
          builder: (c) => TextButton(onPressed: () => c.push(RouteNames.workerProfileSetupPath), child: const Text('open')),
        ),
      ),
      GoRoute(
        path: RouteNames.workerProfileSetupPath,
        builder: (_, _) => WorkerProfileSetupScreen(initialStep: step),
      ),
      GoRoute(path: RouteNames.workerHomePath, builder: (_, _) {
        navigatedHome = true;
        return const Text('WORKER HOME');
      }),
      GoRoute(path: RouteNames.workerProfilePath, builder: (_, _) => const Text('WORKER PROFILE')),
      GoRoute(path: RouteNames.workerVerificationPath, builder: (_, _) => const Text('VERIFY')),
    ]);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith((ref) => user),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> tapPrimary(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('new worker completes setup step by step; each step saves; nothing is invented', (tester) async {
    final repo = await pump(tester, newWorker);

    // Step 1 — about you (prefilled from sign-up)
    expect(find.text(l.workerSetupYouTitle), findsOneWidget);
    await tapPrimary(tester, l.workerSetupSaveContinue);
    expect(repo.updates.last['displayName'], 'Test Worker');
    expect(repo.updates.last['phoneNumber'], '+923001234567');

    // Step 2 — validation first
    expect(find.text(l.workerSetupWorkTitle), findsOneWidget);
    await tapPrimary(tester, l.workerSetupSaveContinue);
    expect(find.text(l.workerSetupHeadlineRequired), findsOneWidget);
    expect(find.text(l.workerSetupCategoryRequired), findsOneWidget);
    expect(find.text(l.workerSetupSkillsRequired), findsOneWidget);
    expect(find.text(l.workerSetupBioRequired), findsOneWidget);
    expect(repo.updates.length, 1, reason: 'invalid step not saved');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Certified Master Electrician');
    await tester.tap(find.text('Electrician'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('House wiring'));
    await tester.enterText(fields.at(2), '7');
    await tester.enterText(fields.at(3), 'Expert in house wiring, UPS and generators for homes.');
    await tester.pumpAndSettle();
    await tapPrimary(tester, l.workerSetupSaveContinue);

    final wp = repo.updates.last['workerProfile'] as Map<String, dynamic>;
    expect(wp['headline'], 'Certified Master Electrician');
    expect(wp['categoryId'], 'electrician');
    expect(wp['categoryName'], 'Electrician');
    expect(wp['skills'], ['House wiring']);
    expect(wp['experience'], 7);
    // Honest starting values for staff-controlled fields
    expect(wp['isVerified'], isFalse);
    expect(wp['averageRating'], 0.0);
    expect(wp['totalReviews'], 0);
    expect(repo.updates.last.containsKey('cnicNumber'), isFalse);

    // Step 3 — area is required, rate is optional
    expect(find.text(l.workerSetupRatesTitle), findsOneWidget);
    await tapPrimary(tester, l.workerSetupSaveContinue);
    expect(find.text(l.workerSetupAreaRequired), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lahore').last);
    await tester.pumpAndSettle();
    await tapPrimary(tester, l.workerSetupSaveContinue);
    final wp3 = repo.updates.last['workerProfile'] as Map<String, dynamic>;
    expect(wp3['hourlyRate'], 0, reason: 'no default rate (old flow saved Rs 1,500)');
    expect(wp3['city'], 'Lahore');
    expect(repo.updates.last['city'], 'Lahore');

    // Step 4 — photos (skippable), Step 5 — verification (skippable)
    expect(find.text(l.workerSetupPhotosTitle), findsOneWidget);
    await tapPrimary(tester, l.onboardingSkipStep);
    expect(find.text(l.workerSetupVerifyTitle), findsOneWidget);
    await tapPrimary(tester, l.onboardingFinish);
    expect(navigatedHome, isTrue);
  });

  testWidgets('editing one section keeps verification, ratings and earnings exactly', (tester) async {
    final repo = await pump(tester, verifiedWorker, step: 3);
    expect(find.byType(LinearProgressIndicator), findsNothing, reason: 'no step bar when editing');
    await tester.enterText(find.byType(TextFormField).at(0), '900');
    await tapPrimary(tester, l.save);

    final wp = repo.updates.single['workerProfile'] as Map<String, dynamic>;
    expect(wp['hourlyRate'], 900);
    expect(wp['isVerified'], isTrue);
    expect(wp['verificationStatus'], 'verified');
    expect(wp['averageRating'], 4.8);
    expect(wp['totalReviews'], 37);
    expect(wp['totalJobsCompleted'], 41);
    expect(wp['totalEarnings'], 120000);
    expect(wp['skills'], ['House wiring']);
    expect(find.text('open'), findsOneWidget, reason: 'returned to the previous screen');
  });

  testWidgets('a failed save shows an error and stays on the step', (tester) async {
    final repo = await pump(tester, verifiedWorker, step: 1);
    repo.fail = true;
    await tapPrimary(tester, l.save);
    expect(find.text(l.profileSaveFailed), findsOneWidget);
    expect(find.text(l.workerSetupYouTitle), findsOneWidget);
  });
}

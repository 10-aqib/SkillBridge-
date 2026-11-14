import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/client/presentation/screens/worker_profile_detail_screen.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:skill_bridge/features/reviews/data/models/review_model.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_profile_screen.dart';

import '../helpers/test_app.dart';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final testWorker = UserModel(
    uid: 'worker_abc',
    email: 'worker@example.com',
    displayName: 'Muhammad Abdullah Khan Lodhi',
    phoneNumber: '+923001234567',
    role: 'worker',
    city: 'Federal Capital Territory, Islamabad, Pakistan',
    rating: 4.85,
    totalReviews: 24,
    isEmailVerified: true,
    isPhoneVerified: true,
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    workerProfile: const WorkerProfileEntity(
      city: 'Islamabad',
      categoryId: 'cat_electrician',
      headline: 'Master Electrician & Certified Solar Installation Specialist',
      bio:
          'Expert residential and commercial electrician with over 8 years of field experience in Islamabad and Rawalpindi. Specialize in DB wiring, breaker replacement, ups inverter setup, and solar wiring.',
      categoryName: 'Electrician',
      hourlyRate: 1500,
      skills: [
        'Wiring',
        'Circuit Breakers',
        'Solar Inverter',
        'UPS Installation',
        'Emergency Repair',
      ],
      languages: ['Urdu', 'English', 'Punjabi'],
      responseTime: 'Usually responds in 15 mins',
      serviceRadius: 25,
      isVerified: true,
      experience: 8,
      averageRating: 4.85,
      totalReviews: 24,
    ),
  );

  final List<ReviewModel> testReviews = [
    ReviewModel(
      id: 'rev_1',
      jobId: 'job_1',
      contractId: 'contract_1',
      reviewerId: 'client_1',
      reviewerName: 'Chaudhry Tariq Mehmood Gujjar Senior Client',
      revieweeId: 'worker_abc',
      revieweeName: 'Muhammad Abdullah Khan Lodhi',
      rating: 5.0,
      comment: 'Excellent work done quickly and cleanly! Highly recommended.',
      createdAt: DateTime(2026, 3, 15),
      helpfulVotes: 3,
      isVerifiedCustomer: true,
      workerReply: 'Thank you for your generous review! Pleasure serving you.',
      workerReplyAt: DateTime(2026, 3, 16),
    ),
  ];

  final client = UserModel(
    uid: 'client_1',
    email: 'client@example.com',
    displayName: 'Client One',
    phoneNumber: '',
    role: 'client',
    isEmailVerified: true,
    isPhoneVerified: false,
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  GoRouter router(Widget home) => GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          name: RouteNames.publicWorkerProfileName,
          path: RouteNames.publicWorkerProfilePath,
          builder: (_, s) => Text('PUBLIC ${s.pathParameters['workerId']}'),
        ),
        for (final p in [
          RouteNames.workerSettingsPath,
          RouteNames.workerVerificationPath,
          RouteNames.workerProfileSetupPath,
          RouteNames.clientChatsPath,
          RouteNames.clientPostJobPath,
        ])
          GoRoute(path: p, builder: (_, s) => Text('PAGE ${s.uri}')),
      ]);

  Future<void> pumpAt(
    WidgetTester tester,
    Size physical,
    double dpr,
    Widget home,
    List<dynamic> overrides, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = physical;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testRouterApp(router: router(home), overrides: overrides, brightness: brightness));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  List<dynamic> ownProfileOverrides() => [
        currentUserProvider.overrideWith((ref) => testWorker),
        userReviewsStreamProvider('worker_abc')
            .overrideWith((ref) => Stream<List<ReviewModel>>.value(testReviews)),
      ];

  group('Worker Profile Responsive Screen Layout Tests', () {
    for (final b in Brightness.values) {
      testWidgets('WorkerProfileScreen renders long content on Pixel 7 without overflow (${b.name})', (tester) async {
        await pumpAt(tester, const Size(1080, 2400), 2.625, const WorkerProfileScreen(), ownProfileOverrides(),
            brightness: b);

        expect(find.text('Muhammad Abdullah Khan Lodhi'), findsOneWidget);
        expect(find.text('Master Electrician & Certified Solar Installation Specialist'), findsWidgets);
        expect(find.text(l.availability), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Rs 1,500 / hour'), 300, scrollable: find.byType(Scrollable).first);
        expect(find.text('Rs 1,500 / hour'), findsOneWidget, reason: 'rate shown with its basis');
        await tester.scrollUntilVisible(find.text('Chaudhry Tariq Mehmood Gujjar Senior Client'), 300, scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('WorkerProfileScreen renders on narrow phone screen (360 width) without overflow', (tester) async {
      await pumpAt(tester, const Size(360, 640), 1.0, const WorkerProfileScreen(), ownProfileOverrides());
      expect(find.text('Muhammad Abdullah Khan Lodhi'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Rs 1,500 / hour'), 300, scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
    });

    testWidgets('own profile links to the public preview', (tester) async {
      await pumpAt(tester, const Size(1080, 2400), 2.625, const WorkerProfileScreen(), ownProfileOverrides());
      await tester.tap(find.byTooltip(l.publicProfilePreview));
      await tester.pumpAndSettle();
      expect(find.text('PUBLIC worker_abc'), findsOneWidget);
    });

    testWidgets('WorkerProfileDetailScreen (client view) renders on Pixel 7 without clipping', (tester) async {
      await pumpAt(tester, const Size(1080, 2400), 2.625, const WorkerProfileDetailScreen(workerId: 'worker_abc'), [
        currentUserProvider.overrideWith((ref) => client),
        workerProfileProvider('worker_abc').overrideWith((ref) => Future<UserEntity?>.value(testWorker)),
        userReviewsStreamProvider('worker_abc')
            .overrideWith((ref) => Stream<List<ReviewModel>>.value(testReviews)),
      ]);

      expect(find.text('Muhammad Abdullah Khan Lodhi'), findsOneWidget);
      expect(find.text('Master Electrician & Certified Solar Installation Specialist'), findsOneWidget);
      expect(find.text(l.verificationBadge), findsOneWidget, reason: 'isVerified is true in the data');
      expect(find.text('4.8'), findsOneWidget, reason: 'rating shown because reviews exist');

      expect(find.widgetWithText(Tab, l.about), findsOneWidget);
      expect(find.widgetWithText(Tab, l.publicProfileWorkTab), findsOneWidget);
      expect(find.widgetWithText(Tab, l.reviews), findsOneWidget);

      expect(find.text(l.message), findsOneWidget);
      expect(tester.renderObject<RenderParagraph>(find.text(l.message)).didExceedMaxLines, isFalse,
          reason: '"Message" must not be cut off at phone width');
      expect(find.text(l.publicProfileRequestBooking), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsNothing, reason: 'no fake share action');

      await tester.tap(find.widgetWithText(Tab, l.reviews));
      await tester.pumpAndSettle();
      expect(find.text(l.publicProfileRatingReviews), findsOneWidget);
      expect(find.text('Chaudhry Tariq Mehmood Gujjar Senior Client'), findsOneWidget);

      await tester.tap(find.widgetWithText(Tab, l.publicProfileWorkTab));
      await tester.pumpAndSettle();
      expect(find.text(l.publicProfileNoPhotos), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('a worker viewing their own public profile sees a preview, not booking actions', (tester) async {
      await pumpAt(tester, const Size(1080, 2400), 2.625, const WorkerProfileDetailScreen(workerId: 'worker_abc'), [
        currentUserProvider.overrideWith((ref) => testWorker),
        workerProfileProvider('worker_abc').overrideWith((ref) => Future<UserEntity?>.value(testWorker)),
        userReviewsStreamProvider('worker_abc')
            .overrideWith((ref) => Stream<List<ReviewModel>>.value(testReviews)),
      ]);
      expect(find.text(l.publicProfileOwnPreview), findsOneWidget);
      expect(find.text(l.publicProfileRequestBooking), findsNothing);
      expect(find.byTooltip(l.reportProfile), findsNothing);
    });

    testWidgets('a worker with no reviews shows New, never an invented rating or price', (tester) async {
      final fresh = UserModel(
        uid: 'w2',
        email: 'w2@example.com',
        displayName: 'New Worker',
        phoneNumber: '',
        role: 'worker',
        isEmailVerified: true,
        isPhoneVerified: false,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        workerProfile: const WorkerProfileEntity(
          headline: 'Plumber',
          bio: 'Leak repairs and fittings for homes.',
          categoryId: 'plumber',
          categoryName: 'Plumber',
          city: 'Lahore',
        ),
      );
      await pumpAt(tester, const Size(1080, 2400), 2.625, const WorkerProfileDetailScreen(workerId: 'w2'), [
        currentUserProvider.overrideWith((ref) => client),
        workerProfileProvider('w2').overrideWith((ref) => Future<UserEntity?>.value(fresh)),
        userReviewsStreamProvider('w2').overrideWith((ref) => Stream<List<ReviewModel>>.value(const [])),
      ]);
      expect(find.text(l.publicProfileNew), findsOneWidget);
      expect(find.text(l.rateOnRequest), findsOneWidget);
      expect(find.text(l.verificationBadge), findsNothing);
      expect(find.text('5.0'), findsNothing);
    });
  });
}

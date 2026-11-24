import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_home_screen.dart';
import 'package:skill_bridge/features/client/presentation/widgets/home_drawer.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import '../helpers/test_app.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/notifications/data/models/notification_model.dart';
import 'package:skill_bridge/features/notifications/presentation/providers/notification_providers.dart';

void main() {
  final testWorker = UserModel(
    uid: 'worker_test_1',
    email: 'aqib@example.com',
    displayName: 'Aqib',
    phoneNumber: '+923001234567',
    role: 'worker',
    city: 'Islamabad',
    rating: 4.8,
    totalReviews: 12,
    isEmailVerified: true,
    isPhoneVerified: true,
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    workerProfile: const WorkerProfileEntity(
      city: 'Islamabad',
      categoryId: 'cat_electrician',
      headline: 'Certified Electrician',
      bio: 'Professional electrical technician.',
      categoryName: 'Electrician',
      hourlyRate: 86,
      skills: ['Wiring', 'Solar'],
      languages: ['English', 'Urdu'],
      responseTime: '15 mins',
      serviceRadius: 25,
      isVerified: true,
      experience: 5,
      averageRating: 4.8,
      totalJobsCompleted: 12,
      availability: 'available',
    ),
  );

  Widget createTestWidget({
    UserEntity? user,
    List<JobEntity> jobs = const [],
    List<JobEntity> directRequests = const [],
    List<ContractEntity> contracts = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => user ?? testWorker),
        openJobsStreamProvider.overrideWith((ref) => Stream.value(jobs)),
        workerDirectRequestsStreamProvider
            .overrideWith((ref) => Stream.value(directRequests)),
        userContractsStreamProvider
            .overrideWith((ref) => Stream.value(contracts)),
      ],
      child: const MaterialApp(
        home: WorkerHomeScreen(),
      ),
    );
  }

  group('WorkerHomeScreen Minimal Premium Dashboard Tests', () {
    testWidgets('renders all key sections on Pixel 7 (412x915)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Header branding
      expect(find.text('Skill'), findsOneWidget);
      expect(find.text('Bridge'), findsOneWidget);
      expect(find.text('Welcome back,'), findsOneWidget);
      expect(find.text('Aqib!'), findsOneWidget);
      expect(find.text('Grow your skills. Build your career.'), findsOneWidget);

      // Availability card
      expect(find.text('Available'), findsOneWidget);
      expect(find.text("You're visible to employers"), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // Stat cards
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Rate'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // Earnings section
      expect(find.text('Your Earnings'), findsOneWidget);

      // Opportunity banner
      expect(find.text('No Earnings Yet'), findsOneWidget);
      expect(find.text('Browse Jobs'), findsOneWidget);

      // Scroll down to reveal Recent Activity and Nearby Jobs
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Recent Activity
      expect(find.text('Recent Activity'), findsOneWidget);

      // Nearby Jobs
      expect(find.text('Jobs Nearby You'), findsOneWidget);
    });

    testWidgets('renders on narrow screen (360x640) without any layout overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // No overflow exceptions thrown
      expect(tester.takeException(), isNull);
    });
  });

  group('Worker home follows light/dark and has the side menu', () {
    Future<void> pumpThemed(WidgetTester tester, Brightness b) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(
        brightness: b,
        overrides: [
          currentUserProvider.overrideWith((ref) => testWorker),
          openJobsStreamProvider.overrideWith((ref) => Stream.value(const <JobEntity>[])),
          workerDirectRequestsStreamProvider.overrideWith((ref) => Stream.value(const <JobEntity>[])),
          userContractsStreamProvider.overrideWith((ref) => Stream.value(const <ContractEntity>[])),
        ],
        home: const WorkerHomeScreen(),
      ));
      await tester.pumpAndSettle();
    }

    for (final b in Brightness.values) {
      testWidgets('background matches the app theme (${b.name})', (tester) async {
        await pumpThemed(tester, b);
        final ctx = tester.element(find.byType(WorkerHomeScreen));
        final scaffold = tester.widget<Scaffold>(find.descendant(of: find.byType(WorkerHomeScreen), matching: find.byType(Scaffold)).first);
        expect(scaffold.backgroundColor, ctx.sb.canvas);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the menu button (top left) opens the worker side menu with the theme switch', (tester) async {
      await pumpThemed(tester, Brightness.light);
      final l = await englishStrings();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeDrawer), findsOneWidget);
      expect(find.text(l.drawerFindJobs), findsOneWidget);
      expect(find.text(l.drawerMyProposals), findsOneWidget);
      expect(find.text(l.drawerSavedJobs), findsOneWidget);
      expect(find.text(l.drawerPostJob), findsNothing, reason: 'client-only shortcut');
      final appearance = find.text(l.settingsAppearance.toUpperCase());
      await tester.scrollUntilVisible(appearance, 200, scrollable: find.descendant(of: find.byType(HomeDrawer), matching: find.byType(Scrollable)).first);
      expect(appearance, findsOneWidget);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    });
  });

  group('Worker notification bell', () {
    Future<void> pumpWithRouter(WidgetTester tester, List<NotificationModel> notes) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const WorkerHomeScreen()),
        GoRoute(path: RouteNames.workerNotificationsPath, builder: (_, _) => const Scaffold(body: Text('NOTIFICATIONS'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(testRouterApp(router: router, overrides: [
        currentUserProvider.overrideWith((ref) => testWorker),
        openJobsStreamProvider.overrideWith((ref) => Stream.value(const <JobEntity>[])),
        workerDirectRequestsStreamProvider.overrideWith((ref) => Stream.value(const <JobEntity>[])),
        userContractsStreamProvider.overrideWith((ref) => Stream.value(const <ContractEntity>[])),
        userNotificationsStreamProvider(testWorker.uid).overrideWith((ref) => Stream.value(notes)),
      ]));
      await tester.pumpAndSettle();
    }

    NotificationModel note({required bool read}) => NotificationModel(
          id: 'n${read ? 1 : 2}', userId: testWorker.uid, title: 'New proposal', body: 'Hi', createdAt: DateTime(2026), isRead: read);

    testWidgets('tapping the bell opens the notifications', (tester) async {
      await pumpWithRouter(tester, [note(read: true)]);
      await tester.tap(find.bySemanticsLabel('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
    });

    testWidgets('no red dot when everything is read', (tester) async {
      await pumpWithRouter(tester, [note(read: true)]);
      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Notifications, \d')), findsNothing);
    });

    testWidgets('the red dot and count show while something is unread', (tester) async {
      await pumpWithRouter(tester, [note(read: true), note(read: false)]);
      expect(find.bySemanticsLabel('Notifications, 1'), findsOneWidget);
    });
  });
}

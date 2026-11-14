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
}

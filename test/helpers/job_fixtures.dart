import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';

/// Test job (no fake data reaches the app — tests only).
JobModel testJob(
  String id, {
  String clientId = 'client_1',
  String clientName = 'Ayesha Khan',
  String title = 'Fix two kitchen sockets',
  String description = 'Two sockets spark when plugged in; please bring a tester.',
  String categoryId = 'electrician',
  String categoryName = 'Electrician',
  List<String> skills = const ['House wiring'],
  double budgetMin = 2000,
  double budgetMax = 3000,
  String budgetType = 'fixed',
  JobStatus status = JobStatus.open,
  String? selectedWorkerId,
  String? selectedWorkerName,
  DateTime? createdAt,
  String urgency = 'within_3_days',
  int totalProposals = 0,
}) =>
    JobModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      title: title,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      requiredSkills: skills,
      jobType: JobType.temporary,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      budgetType: budgetType,
      address: 'Gulberg',
      city: 'Lahore',
      status: status,
      urgency: urgency,
      images: const [],
      totalProposals: totalProposals,
      selectedWorkerId: selectedWorkerId,
      selectedWorkerName: selectedWorkerName,
      createdAt: createdAt ?? DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      searchKeywords: JobSearchIndex.keywordsFor(
        title: title,
        categoryName: categoryName,
        categoryId: categoryId,
        skills: skills,
        description: description,
        city: 'Lahore',
      ),
    );

UserModel testUser(String uid, {String role = 'client', bool active = true, String name = 'Ayesha Khan', String city = 'Lahore'}) => UserModel(
      uid: uid,
      email: '$uid@example.com',
      displayName: name,
      phoneNumber: '+923001234567',
      role: role,
      isEmailVerified: true,
      isPhoneVerified: false,
      isActive: active,
      city: city.isEmpty ? null : city,
      onboardingCompleted: true,
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 1, 10),
    );

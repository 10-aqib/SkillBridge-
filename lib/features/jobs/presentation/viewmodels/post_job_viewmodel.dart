import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';

enum PostJobError { notClient, suspended, failed }

class PostJobState {
  const PostJobState({this.isLoading = false, this.error, this.jobId, this.queuedOffline = false});

  final bool isLoading;
  final PostJobError? error;

  /// Set once the job is saved (new or edited).
  final String? jobId;
  final bool queuedOffline;
}

/// What the client filled in on the job form.
class JobDraft {
  const JobDraft({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.skills,
    required this.budgetType,
    required this.budgetMin,
    required this.budgetMax,
    required this.city,
    required this.area,
    required this.urgency,
    this.preferredDate,
    this.images = const [],
  });

  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final List<String> skills;
  final String budgetType;
  final double budgetMin;
  final double budgetMax;
  final String city;
  final String area;
  final String urgency;
  final DateTime? preferredDate;
  final List<String> images;
}

/// Publishes or edits a job. Ownership, status, counters and timestamps are
/// set here and enforced again by the Firestore rules — never taken from
/// the form.
class PostJobNotifier extends Notifier<PostJobState> {
  @override
  PostJobState build() => const PostJobState();

  PostJobError? _checkUser() {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isClient) return PostJobError.notClient;
    if (!user.isActive) return PostJobError.suspended;
    return null;
  }

  Future<void> publish(JobDraft d, {String? directWorkerId, String? directWorkerName}) async {
    if (state.isLoading || state.jobId != null) return; // no duplicate submissions
    final problem = _checkUser();
    if (problem != null) {
      state = PostJobState(error: problem);
      return;
    }
    final user = ref.read(currentUserProvider)!;
    state = const PostJobState(isLoading: true);
    final now = DateTime.now();
    final job = JobModel(
      id: '',
      clientId: user.uid,
      clientName: user.displayName,
      clientPhotoUrl: user.photoUrl,
      title: d.title,
      description: d.description,
      categoryId: d.categoryId,
      categoryName: d.categoryName,
      requiredSkills: d.skills,
      jobType: JobType.temporary,
      budgetMin: d.budgetMin,
      budgetMax: d.budgetMax,
      budgetType: d.budgetType,
      address: d.area,
      city: d.city,
      status: JobStatus.open,
      urgency: d.urgency,
      images: d.images,
      totalProposals: 0,
      selectedWorkerId: directWorkerId,
      selectedWorkerName: directWorkerName,
      startDate: d.preferredDate,
      createdAt: now,
      updatedAt: now,
    );
    try {
      final result = await ref.read(jobRemoteDataSourceProvider).createJob(job);
      state = PostJobState(jobId: result.id, queuedOffline: result.queuedOffline);
    } catch (_) {
      state = const PostJobState(error: PostJobError.failed);
    }
  }

  Future<void> saveEdit(JobEntity original, JobDraft d) async {
    if (state.isLoading) return;
    final problem = _checkUser();
    if (problem != null) {
      state = PostJobState(error: problem);
      return;
    }
    state = const PostJobState(isLoading: true);
    final job = JobModel(
      id: original.id,
      clientId: original.clientId,
      clientName: original.clientName,
      clientPhotoUrl: original.clientPhotoUrl,
      title: d.title,
      description: d.description,
      categoryId: d.categoryId,
      categoryName: d.categoryName,
      requiredSkills: d.skills,
      jobType: original.jobType,
      budgetMin: d.budgetMin,
      budgetMax: d.budgetMax,
      budgetType: d.budgetType,
      address: d.area,
      city: d.city,
      status: original.status,
      urgency: d.urgency,
      images: d.images,
      totalProposals: original.totalProposals,
      selectedWorkerId: original.selectedWorkerId,
      selectedWorkerName: original.selectedWorkerName,
      startDate: d.preferredDate,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(jobRemoteDataSourceProvider).editJob(job);
      state = PostJobState(jobId: original.id);
    } catch (_) {
      state = const PostJobState(error: PostJobError.failed);
    }
  }
}

final postJobNotifierProvider = NotifierProvider.autoDispose<PostJobNotifier, PostJobState>(PostJobNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';

class PostJobState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const PostJobState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  PostJobState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return PostJobState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class PostJobNotifier extends Notifier<PostJobState> {
  @override
  PostJobState build() {
    return const PostJobState();
  }

  Future<void> submitJob({
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    required List<String> requiredSkills,
    required JobType jobType,
    required double budgetMin,
    required double budgetMax,
    required String budgetType,
    required String address,
    required String city,
    required String urgency,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final job = JobModel(
        id: '',
        clientId: currentUser.uid,
        clientName: currentUser.displayName,
        clientPhotoUrl: currentUser.photoUrl,
        title: title,
        description: description,
        categoryId: categoryId,
        categoryName: categoryName,
        requiredSkills: requiredSkills,
        jobType: jobType,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        budgetType: budgetType,
        address: address,
        city: city,
        status: JobStatus.open,
        urgency: urgency,
        images: const [],
        totalProposals: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dataSource = ref.read(jobRemoteDataSourceProvider);
      await dataSource.createJob(job);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final postJobNotifierProvider =
    NotifierProvider<PostJobNotifier, PostJobState>(PostJobNotifier.new);

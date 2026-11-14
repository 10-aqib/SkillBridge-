import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/client/domain/entities/nearby_worker_entity.dart';

import 'package:skill_bridge/features/client/data/datasources/worker_remote_datasource.dart';
import 'package:skill_bridge/features/client/data/repositories/worker_repository_impl.dart';
import 'package:skill_bridge/features/client/domain/repositories/worker_repository.dart';
import 'package:skill_bridge/features/client/domain/usecases/get_nearby_workers_usecase.dart';

final workerRemoteDataSourceProvider = Provider<WorkerRemoteDataSource>((ref) {
  return WorkerRemoteDataSourceImpl(firestore: ref.watch(firestoreProvider));
});

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return WorkerRepositoryImpl(ref.watch(workerRemoteDataSourceProvider));
});

final getNearbyWorkersUseCaseProvider = Provider<GetNearbyWorkersUseCase>((
  ref,
) {
  return GetNearbyWorkersUseCase(ref.watch(workerRepositoryProvider));
});

class NearbyWorkerParams {
  final GeoPointLocation location;
  final double radiusKm;
  const NearbyWorkerParams(this.location, this.radiusKm);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyWorkerParams &&
          location == other.location &&
          radiusKm == other.radiusKm;

  @override
  int get hashCode => location.hashCode ^ radiusKm.hashCode;
}

final nearbyWorkersProvider =
    StreamProvider.family<List<NearbyWorkerEntity>, NearbyWorkerParams>((
      ref,
      params,
    ) {
      final usecase = ref.watch(getNearbyWorkersUseCaseProvider);
      return usecase(params.location, maxDistanceKm: params.radiusKm);
    });

final youMightNeedWorkersProvider = StreamProvider<List<UserModel>>((ref) {
  final dataSource = ref.watch(workerRemoteDataSourceProvider);
  return dataSource.getWorkersStream().map((workers) {
    final workerByCategory = <String, UserModel>{};
    for (final worker in workers) {
      final profile = worker.workerProfile;
      if (!worker.isActive ||
          profile == null ||
          worker.displayName.trim().isEmpty ||
          profile.categoryName.trim().isEmpty) {
        continue;
      }

      final categoryKey = profile.categoryId.trim().isNotEmpty
          ? profile.categoryId.trim().toLowerCase()
          : profile.categoryName.trim().toLowerCase();
      final current = workerByCategory[categoryKey];
      if (current == null || _hasMoreCompletedWork(worker, current)) {
        workerByCategory[categoryKey] = worker;
      }
    }

    final result = workerByCategory.values.toList()
      ..sort(
        (a, b) => a.workerProfile!.categoryName.toLowerCase().compareTo(
          b.workerProfile!.categoryName.toLowerCase(),
        ),
      );
    return result;
  });
});

bool _hasMoreCompletedWork(UserModel candidate, UserModel current) {
  final candidateProfile = candidate.workerProfile!;
  final currentProfile = current.workerProfile!;
  if (candidateProfile.totalJobsCompleted !=
      currentProfile.totalJobsCompleted) {
    return candidateProfile.totalJobsCompleted >
        currentProfile.totalJobsCompleted;
  }
  if (candidateProfile.totalReviews != currentProfile.totalReviews) {
    return candidateProfile.totalReviews > currentProfile.totalReviews;
  }
  return candidate.displayName.compareTo(current.displayName) < 0;
}

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

final getNearbyWorkersUseCaseProvider = Provider<GetNearbyWorkersUseCase>((ref) {
  return GetNearbyWorkersUseCase(ref.watch(workerRepositoryProvider));
});

final nearbyWorkersProvider = StreamProvider.family<List<NearbyWorkerEntity>, GeoPointLocation>((ref, userLocation) {
  final usecase = ref.watch(getNearbyWorkersUseCaseProvider);
  return usecase(userLocation);
});

final verifiedWorkersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
});


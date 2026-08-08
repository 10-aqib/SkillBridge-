import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AdminRemoteDataSource(firestore: firestore);
});

final adminStatsStreamProvider = StreamProvider<AdminStatsModel>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getStatsStream();
});

final adminUsersStreamProvider = StreamProvider<List<UserEntity>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getUsersStream();
});

final adminJobsStreamProvider = StreamProvider<List<JobEntity>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getJobsStream();
});

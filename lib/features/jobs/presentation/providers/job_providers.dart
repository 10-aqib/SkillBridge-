import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/data/datasources/job_remote_datasource.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';

final jobRemoteDataSourceProvider = Provider<JobRemoteDataSource>((ref) {
  return JobRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

/// Real-time stream of all open jobs
final openJobsStreamProvider = StreamProvider<List<JobEntity>>((ref) {
  return ref.watch(jobRemoteDataSourceProvider).getOpenJobs();
});

/// Real-time stream of jobs posted by the currently logged in client
final clientJobsStreamProvider = StreamProvider<List<JobEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(jobRemoteDataSourceProvider).getJobsByClient(user.uid);
});

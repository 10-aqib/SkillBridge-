import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Real-time stream of direct job requests for the currently logged in worker
final workerDirectRequestsStreamProvider = StreamProvider<List<JobEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isWorker) return Stream.value([]);
  return ref.watch(jobRemoteDataSourceProvider).getDirectRequests(user.uid);
});

/// Live job by id (used by the shared job details screen). A refused read
/// (closed job, someone else's direct request) is final: no automatic retry.
/// Restarts when the signed-in account changes, so a refusal seen by one
/// account (e.g. at sign-out) never sticks to the next one.
final jobByIdProvider = StreamProvider.family<JobEntity?, String>(
  (ref, jobId) {
    ref.watch(currentUserProvider.select((u) => u?.uid));
    return ref.watch(jobRemoteDataSourceProvider).watchJob(jobId);
  },
  retry: jobReadRetry,
);

/// Retry transient failures a few times; never retry a permission refusal.
Duration? jobReadRetry(int retryCount, Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') return null;
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 400 * (1 << retryCount));
}


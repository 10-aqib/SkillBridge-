import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/proposals/data/datasources/proposal_remote_datasource.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';

final proposalRemoteDataSourceProvider = Provider<ProposalRemoteDataSource>((ref) {
  return ProposalRemoteDataSourceImpl(ref.watch(firestoreProvider), ref.watch(firebaseAuthProvider));
});

/// A refused read is final; other failures retry a few times.
Duration? _retry(int count, Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') return null;
  return count >= 3 ? null : Duration(milliseconds: 400 * (1 << count));
}

/// The signed-in worker's proposals, newest first.
final workerProposalsStreamProvider = StreamProvider<List<ProposalEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isWorker) return Stream.value(const []);
  return ref.watch(proposalRemoteDataSourceProvider).getProposalsByWorker(user.uid);
}, retry: _retry);

/// The signed-in worker's proposal for a job, if any (any status).
final myProposalForJobProvider = Provider.family<AsyncValue<ProposalEntity?>, String>((ref, jobId) {
  return ref.watch(workerProposalsStreamProvider).whenData((list) {
    for (final p in list) {
      if (p.jobId == jobId) return p;
    }
    return null;
  });
});

/// Proposals received for one of the signed-in client's jobs.
final jobProposalsStreamProvider = StreamProvider.family<List<ProposalEntity>, String>((ref, jobId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(proposalRemoteDataSourceProvider).getProposalsForJob(jobId, user.uid);
}, retry: _retry);

/// One proposal, live (worker who sent it or client who received it).
/// Restarts when the signed-in account changes.
final proposalByIdProvider = StreamProvider.family<ProposalEntity?, String>((ref, id) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  return ref.watch(proposalRemoteDataSourceProvider).watchProposal(id);
}, retry: _retry);

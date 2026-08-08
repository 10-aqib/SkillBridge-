import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/proposals/data/datasources/proposal_remote_datasource.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';

final proposalRemoteDataSourceProvider =
    Provider<ProposalRemoteDataSource>((ref) {
  return ProposalRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

/// Real-time stream of proposals submitted by current worker
final workerProposalsStreamProvider =
    StreamProvider<List<ProposalEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref
      .watch(proposalRemoteDataSourceProvider)
      .getProposalsByWorker(user.uid);
});

/// Real-time stream of proposals submitted for a specific job
final jobProposalsStreamProvider =
    StreamProvider.family<List<ProposalEntity>, String>((ref, jobId) {
  return ref
      .watch(proposalRemoteDataSourceProvider)
      .getProposalsForJob(jobId);
});

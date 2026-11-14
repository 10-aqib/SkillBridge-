import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/proposals/data/models/proposal_model.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';

/// Why a proposal action failed, for a clear message.
enum ProposalFailure { alreadySent, jobUnavailable, notAllowed, network, other }

class ProposalException implements Exception {
  const ProposalException(this.reason);
  final ProposalFailure reason;
  @override
  String toString() => 'ProposalException($reason)';
}

ProposalFailure proposalFailureOf(Object e) {
  if (e is ProposalException) return e.reason;
  if (e is FirebaseException) {
    return switch (e.code) {
      'permission-denied' => ProposalFailure.notAllowed,
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' => ProposalFailure.network,
      'not-found' => ProposalFailure.jobUnavailable,
      _ => ProposalFailure.other,
    };
  }
  return ProposalFailure.other;
}

abstract class ProposalRemoteDataSource {
  /// Sends a new proposal, or re-sends [existing] if it was withdrawn.
  Future<String> submitProposal(ProposalModel proposal, {ProposalEntity? existing});
  Future<void> withdrawProposal(String proposalId);
  Future<void> markViewed(String proposalId);
  Future<void> rejectProposal(String proposalId);

  /// Hires the worker through the trusted acceptProposalCall function: in one
  /// server transaction it accepts this proposal, assigns the job, closes the
  /// other pending proposals and creates the contract and job chat. Returns
  /// the contract id; repeating the call returns the same contract.
  Future<String> acceptProposal({
    required ProposalEntity proposal,
    required JobEntity job,
    required String clientName,
    String? clientPhotoUrl,
  });

  /// The client's view of a job's proposals.
  Stream<List<ProposalModel>> getProposalsForJob(String jobId, String clientId);
  Stream<List<ProposalModel>> getProposalsByWorker(String workerId);
  Stream<ProposalModel?> watchProposal(String proposalId);
}

class ProposalRemoteDataSourceImpl implements ProposalRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;

  ProposalRemoteDataSourceImpl(this._firestore, [this._functions]);

  CollectionReference<Map<String, dynamic>> get _proposals => _firestore.collection(FirestorePaths.proposals);

  @override
  Future<String> submitProposal(ProposalModel proposal, {ProposalEntity? existing}) async {
    final id = ProposalEntity.idFor(proposal.jobId, proposal.workerId);
    if (existing != null && existing.status != ProposalStatus.withdrawn) {
      throw const ProposalException(ProposalFailure.alreadySent);
    }
    final ref = _proposals.doc(id);
    final batch = _firestore.batch();
    if (existing != null) {
      batch.update(ref, proposal.toResubmitMap());
    } else {
      // A second create for the same id is refused by the rules (no duplicates).
      batch.set(ref, proposal.toCreateMap());
    }
    batch.set(_firestore.collection(FirestorePaths.notifications).doc(), {
      'userId': proposal.clientId,
      'title': 'New Proposal Received',
      'body': '${proposal.workerName} sent a proposal for "${proposal.jobTitle}".',
      'payload': {'jobId': proposal.jobId, 'proposalId': id},
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    try {
      await batch.commit().timeout(const Duration(seconds: 20));
      return id;
    } on FirebaseException catch (e) {
      // Refused: the job closed or filled, or a proposal already exists.
      if (e.code == 'permission-denied') {
        throw ProposalException(existing == null ? ProposalFailure.jobUnavailable : ProposalFailure.notAllowed);
      }
      rethrow;
    }
  }

  @override
  Future<void> withdrawProposal(String proposalId) => _proposals.doc(proposalId).update({
        'status': ProposalStatus.withdrawn.value,
        'withdrawnAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> markViewed(String proposalId) =>
      _proposals.doc(proposalId).update({'viewedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> rejectProposal(String proposalId) => _proposals.doc(proposalId).update({
        'status': ProposalStatus.rejected.value,
        'closedReason': 'client',
        'decidedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<String> acceptProposal({
    required ProposalEntity proposal,
    required JobEntity job,
    required String clientName,
    String? clientPhotoUrl,
  }) async {
    try {
      final result = await (_functions ?? FirebaseFunctions.instance)
          .httpsCallable('acceptProposalCall')
          .call<Map<String, dynamic>>({'proposalId': proposal.id});
      return (result.data['contractId'] as String?) ?? proposal.id;
    } on FirebaseFunctionsException catch (e) {
      throw ProposalException(switch (e.code) {
        // The job is no longer open, or the proposal is no longer pending.
        'failed-precondition' || 'not-found' => ProposalFailure.jobUnavailable,
        'permission-denied' || 'unauthenticated' => ProposalFailure.notAllowed,
        'unavailable' || 'deadline-exceeded' => ProposalFailure.network,
        _ => ProposalFailure.other,
      });
    }
  }

  List<ProposalModel> _sorted(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(ProposalModel.fromSnapshot).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<ProposalModel>> getProposalsForJob(String jobId, String clientId) => _proposals
      .where('jobId', isEqualTo: jobId)
      // Required by the rules: clients read only proposals sent to them.
      .where('clientId', isEqualTo: clientId)
      .snapshots()
      .map(_sorted);

  @override
  Stream<List<ProposalModel>> getProposalsByWorker(String workerId) =>
      _proposals.where('workerId', isEqualTo: workerId).snapshots().map(_sorted);

  @override
  Stream<ProposalModel?> watchProposal(String proposalId) =>
      _proposals.doc(proposalId).snapshots().map((d) => d.exists ? ProposalModel.fromSnapshot(d) : null);
}

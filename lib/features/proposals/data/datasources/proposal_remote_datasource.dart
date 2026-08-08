import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/features/proposals/data/models/proposal_model.dart';

abstract class ProposalRemoteDataSource {
  Future<String> submitProposal(ProposalModel proposal);
  Future<void> updateProposalStatus(String proposalId, String status);
  Future<void> acceptProposal({
    required String proposalId,
    required String jobId,
    required String workerId,
    required String workerName,
  });
  Stream<List<ProposalModel>> getProposalsForJob(String jobId);
  Stream<List<ProposalModel>> getProposalsByWorker(String workerId);
}

class ProposalRemoteDataSourceImpl implements ProposalRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProposalRemoteDataSourceImpl(this._firestore);

  @override
  Future<String> submitProposal(ProposalModel proposal) async {
    try {
      final batch = _firestore.batch();
      final proposalRef =
          _firestore.collection(FirestorePaths.proposals).doc();

      batch.set(proposalRef, proposal.toMap());

      final jobRef =
          _firestore.collection(FirestorePaths.jobs).doc(proposal.jobId);
      batch.update(jobRef, {'totalProposals': FieldValue.increment(1)});

      // Create in-app notification for the client (FYP Spec 2.1.10 / B8)
      if (proposal.clientId.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': proposal.clientId,
          'title': 'New Proposal Received',
          'body':
              '${proposal.workerName} submitted a proposal for "${proposal.jobTitle}".',
          'payload': {'jobId': proposal.jobId, 'proposalId': proposalRef.id},
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      await batch.commit();
      return proposalRef.id;
    } catch (e) {
      throw ServerException('Failed to submit proposal: $e');
    }
  }

  @override
  Future<void> updateProposalStatus(String proposalId, String status) async {
    try {
      await _firestore
          .collection(FirestorePaths.proposals)
          .doc(proposalId)
          .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw ServerException('Failed to update proposal status: $e');
    }
  }

  @override
  Future<void> acceptProposal({
    required String proposalId,
    required String jobId,
    required String workerId,
    required String workerName,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Accept the chosen proposal
      final acceptedRef =
          _firestore.collection(FirestorePaths.proposals).doc(proposalId);
      batch.update(acceptedRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Query all other proposals for this job and reject them
      final otherProposals = await _firestore
          .collection(FirestorePaths.proposals)
          .where('jobId', isEqualTo: jobId)
          .get();

      for (var doc in otherProposals.docs) {
        if (doc.id != proposalId) {
          batch.update(doc.reference, {
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 3. Atomically update job status to 'assigned' and assign worker
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc(jobId);
      batch.update(jobRef, {
        'status': 'assigned',
        'selectedWorkerId': workerId,
        'selectedWorkerName': workerName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Create Contract with 10% Flat Rate Commission (FYP Spec 2.1.7 / B6)
      final proposalDoc = await _firestore
          .collection(FirestorePaths.proposals)
          .doc(proposalId)
          .get();
      final jobDoc =
          await _firestore.collection(FirestorePaths.jobs).doc(jobId).get();

      final proposalData = proposalDoc.data() ?? {};
      final jobData = jobDoc.data() ?? {};

      final double rate = (proposalData['proposedRate'] ?? 0.0).toDouble();
      final double commission = (rate * 0.10).roundToDouble(); // 10% Flat Rate
      final double workerEarnings = rate - commission;

      final contractRef =
          _firestore.collection(FirestorePaths.contracts).doc();
      batch.set(contractRef, {
        'jobId': jobId,
        'jobTitle': proposalData['jobTitle'] ?? jobData['title'] ?? '',
        'proposalId': proposalId,
        'clientId': proposalData['clientId'] ?? jobData['clientId'] ?? '',
        'clientName': jobData['clientName'] ?? '',
        'clientPhotoUrl': jobData['clientPhotoUrl'],
        'workerId': workerId,
        'workerName': workerName,
        'workerPhotoUrl': proposalData['workerPhotoUrl'],
        'agreedRate': rate,
        'rateType': proposalData['rateType'] ?? 'fixed',
        'totalAmount': rate,
        'commissionRate': 0.10,
        'commissionAmount': commission,
        'workerEarnings': workerEarnings,
        'paymentStatus': 'unpaid',
        'paymentMethod': 'jazzcash',
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'clientReviewed': false,
        'workerReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Create in-app notification for the worker (FYP Spec 2.1.10 / B8)
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': workerId,
        'title': 'Proposal Accepted! 🎉',
        'body':
            'Your proposal for "${proposalData['jobTitle'] ?? jobData['title'] ?? ''}" was accepted!',
        'payload': {'jobId': jobId, 'proposalId': proposalId},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 6. Create or update chat thread between Client & Worker (FYP Spec 2.1.9 / B8)
      final clientId = proposalData['clientId'] ?? jobData['clientId'] ?? '';
      final clientName = jobData['clientName'] ?? 'Client';
      if (clientId.toString().isNotEmpty) {
        final chatRef = _firestore.collection(FirestorePaths.chats).doc();
        batch.set(chatRef, {
          'participantIds': [clientId, workerId],
          'participantNames': {
            clientId: clientName,
            workerId: workerName,
          },
          'participantPhotos': {
            clientId: jobData['clientPhotoUrl'],
            workerId: proposalData['workerPhotoUrl'],
          },
          'lastMessage':
              'Proposal accepted! You can now message each other • بات چیت شروع ہوئی',
          'lastMessageSenderId': clientId,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': {
            clientId: 0,
            workerId: 1,
          },
          'relatedJobId': jobId,
          'relatedJobTitle':
              proposalData['jobTitle'] ?? jobData['title'] ?? '',
        });
      }

      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to accept proposal and assign job: $e');
    }
  }

  @override
  Stream<List<ProposalModel>> getProposalsForJob(String jobId) {
    return _firestore
        .collection(FirestorePaths.proposals)
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ProposalModel.fromSnapshot(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<ProposalModel>> getProposalsByWorker(String workerId) {
    return _firestore
        .collection(FirestorePaths.proposals)
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ProposalModel.fromSnapshot(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}

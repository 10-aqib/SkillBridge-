import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_model.dart';

abstract class ContractRemoteDataSource {
  Future<String> createContract(ContractModel contract);
  Future<String> createDirectContract({
    required String clientId,
    required String clientName,
    required String? clientPhotoUrl,
    required String workerId,
    required String workerName,
    required String? workerPhotoUrl,
    required String categoryName,
    required double hourlyRatePkr,
    required int hours,
    required double totalAmount,
    required String address,
    required String city,
    required DateTime date,
    required String timeSlot,
    required String phone,
    required String paymentMethod,
  });
  Future<void> updateContractStatus(String contractId, String status);
  Stream<List<ContractModel>> getContractsByClient(String clientId);
  Stream<List<ContractModel>> getContractsByWorker(String workerId);
}

class ContractRemoteDataSourceImpl implements ContractRemoteDataSource {
  final FirebaseFirestore _firestore;

  ContractRemoteDataSourceImpl(this._firestore);

  @override
  Future<String> createContract(ContractModel contract) async {
    try {
      final batch = _firestore.batch();
      final contractRef =
          _firestore.collection(FirestorePaths.contracts).doc();

      batch.set(contractRef, contract.toMap());

      // Update job status to in_progress and assign worker
      final jobRef =
          _firestore.collection(FirestorePaths.jobs).doc(contract.jobId);
      batch.update(jobRef, {
        'status': 'in_progress',
        'selectedWorkerId': contract.workerId,
        'selectedWorkerName': contract.workerName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update proposal status to accepted
      final proposalRef = _firestore
          .collection(FirestorePaths.proposals)
          .doc(contract.proposalId);
      batch.update(proposalRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return contractRef.id;
    } catch (e) {
      throw ServerException('Failed to create contract: $e');
    }
  }

  @override
  Future<String> createDirectContract({
    required String clientId,
    required String clientName,
    required String? clientPhotoUrl,
    required String workerId,
    required String workerName,
    required String? workerPhotoUrl,
    required String categoryName,
    required double hourlyRatePkr,
    required int hours,
    required double totalAmount,
    required String address,
    required String city,
    required DateTime date,
    required String timeSlot,
    required String phone,
    required String paymentMethod,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // 1. Create a job record
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc();
      final jobMap = {
        'clientId': clientId,
        'clientName': clientName,
        'clientPhotoUrl': clientPhotoUrl,
        'title': 'Direct Hire: $categoryName',
        'description': 'Direct booking for $hours hour(s) of $categoryName work.',
        'categoryId': '',
        'categoryName': categoryName,
        'requiredSkills': <String>[],
        'jobType': 'temporary',
        'budgetMin': hourlyRatePkr,
        'budgetMax': hourlyRatePkr * hours,
        'budgetType': 'hourly',
        'address': address,
        'city': '',
        'status': 'in_progress',
        'urgency': 'normal',
        'images': <String>[],
        'totalProposals': 0,
        'selectedWorkerId': workerId,
        'selectedWorkerName': workerName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(jobRef, jobMap);

      // 2. Create a contract record
      final contractRef =
          _firestore.collection(FirestorePaths.contracts).doc();
      final commissionRate = 0.10;
      final commissionAmount = totalAmount * commissionRate;
      final workerEarnings = totalAmount - commissionAmount;

      final contractMap = {
        'jobId': jobRef.id,
        'jobTitle': 'Direct Hire: $categoryName',
        'proposalId': 'direct_hire',
        'clientId': clientId,
        'clientName': clientName,
        'clientPhotoUrl': clientPhotoUrl,
        'workerId': workerId,
        'workerName': workerName,
        'workerPhotoUrl': workerPhotoUrl,
        'agreedRate': hourlyRatePkr,
        'rateType': 'hourly',
        'totalAmount': totalAmount,
        'commissionRate': commissionRate,
        'commissionAmount': commissionAmount,
        'workerEarnings': workerEarnings,
        'paymentStatus': 'escrow',
        'paymentMethod': paymentMethod.toLowerCase(),
        'paymentTransactionId': null,
        'serviceAddress': address,
        'serviceCity': city,
        'serviceDate': Timestamp.fromDate(date),
        'serviceTimeSlot': timeSlot,
        'clientPhone': phone,
        'status': 'pending',
        'startDate': Timestamp.fromDate(now),
        'endDate': null,
        'completedAt': null,
        'clientReviewed': false,
        'workerReviewed': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(contractRef, contractMap);

      // 3. Create a notification record for worker
      final notifRef =
          _firestore.collection(FirestorePaths.notifications).doc();
      final notifMap = {
        'userId': workerId,
        'title': 'New Direct Booking',
        'body': 'You have received a new booking request from $clientName for $categoryName!',
        'type': 'booking',
        'referenceId': contractRef.id,
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
      };
      batch.set(notifRef, notifMap);

      await batch.commit();
      return contractRef.id;
    } catch (e) {
      throw ServerException('Failed to create direct contract: $e');
    }
  }

  @override
  Future<void> updateContractStatus(String contractId, String status) async {
    try {
      final contractDoc = await _firestore
          .collection(FirestorePaths.contracts)
          .doc(contractId)
          .get();
      if (!contractDoc.exists) {
        throw ServerException('Contract not found');
      }
      final data = contractDoc.data()!;
      final String jobId = data['jobId'] ?? '';

      final batch = _firestore.batch();
      final contractRef =
          _firestore.collection(FirestorePaths.contracts).doc(contractId);
      batch.update(contractRef, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });

      if (jobId.isNotEmpty) {
        final jobRef = _firestore.collection(FirestorePaths.jobs).doc(jobId);
        batch.update(jobRef, {
          'status': status == 'completed' ? 'completed' : status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Add notification for client if status is active (accepted) or rejected
      if (status == 'active' || status == 'rejected') {
        final clientId = data['clientId'];
        final workerName = data['workerName'];
        if (clientId != null && workerName != null) {
          final notifRef = _firestore.collection(FirestorePaths.notifications).doc();
          final isAccepted = status == 'active';
          final title = isAccepted ? 'Booking Accepted' : 'Booking Declined';
          final body = isAccepted 
              ? '$workerName has accepted your booking request!'
              : '$workerName has declined your booking request.';
          
          batch.set(notifRef, {
            'userId': clientId,
            'title': title,
            'body': body,
            'type': 'booking_update',
            'referenceId': contractId,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to update contract status: $e');
    }
  }

  @override
  Stream<List<ContractModel>> getContractsByClient(String clientId) {
    return _firestore
        .collection(FirestorePaths.contracts)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ContractModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Stream<List<ContractModel>> getContractsByWorker(String workerId) {
    return _firestore
        .collection(FirestorePaths.contracts)
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ContractModel.fromSnapshot(doc)).toList();
    });
  }
}

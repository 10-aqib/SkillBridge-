import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_activity.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_model.dart';
import 'package:uuid/uuid.dart';

/// Why a contract action failed, for a clear message.
enum ContractFailure { notAllowed, wrongState, invalid, network, other }

class ContractException implements Exception {
  const ContractException(this.reason, [this.message]);
  final ContractFailure reason;
  final String? message;
  @override
  String toString() => 'ContractException($reason, $message)';
}

ContractFailure contractFailureOf(Object e) {
  if (e is ContractException) return e.reason;
  final code = e is FirebaseFunctionsException
      ? e.code
      : e is FirebaseException
          ? e.code
          : '';
  return switch (code) {
    'permission-denied' || 'unauthenticated' || 'not-found' => ContractFailure.notAllowed,
    'failed-precondition' => ContractFailure.wrongState,
    'invalid-argument' => ContractFailure.invalid,
    'unavailable' || 'deadline-exceeded' || 'network-request-failed' => ContractFailure.network,
    _ => ContractFailure.other,
  };
}

/// Reasons a contract may be cancelled (stored as these codes).
const contractCancelReasons = ['schedule_conflict', 'no_longer_needed', 'agreed_with_other_party', 'safety_concern', 'other'];

abstract class ContractRemoteDataSource {
  /// A client's booking request to one worker (pending until the worker
  /// answers). Lifecycle changes afterwards go through [ContractActions].
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
  Stream<List<ContractModel>> getContractsByClient(String clientId);
  Stream<List<ContractModel>> getContractsByWorker(String workerId);
  Stream<ContractModel?> watchContract(String contractId);

  /// The signed-in party's contract for a job, if any (newest first).
  Stream<ContractModel?> watchContractForJob(String jobId, {required String uid, required bool asClient});

  /// The worker's progress updates, newest first (parties only).
  Stream<List<ContractUpdate>> watchUpdates(String contractId);

  /// Every submission of the work, oldest first (parties only).
  Stream<List<ContractSubmission>> watchSubmissions(String contractId);
}

/// Hiring and lifecycle steps, decided by the trusted Cloud Functions
/// (functions/src/contracts.ts). The app never writes contract status.
abstract class ContractActions {
  Future<String> acceptProposal(String proposalId);

  /// The requested worker answers a direct request (an open job sent only to
  /// them). Accepting creates the contract and returns its id.
  Future<String?> respondToDirectRequest(String jobId, {required bool accept});
  Future<void> respondToRequest(String contractId, {required bool accept});
  Future<void> startWork(String contractId);
  Future<void> submitWork(String contractId, {required String note, List<String> attachments = const []});
  Future<void> confirmCompletion(String contractId);
  Future<void> cancel(String contractId, {required String reason, String note = ''});
  Future<void> shareAddress(String contractId, String address);

  /// The client sends submitted work back with what to change (Phase 4B).
  Future<void> requestRevision(String contractId, {required String note});

  /// The hired worker posts a progress update. [requestId] is chosen once
  /// per update and reused on retry, so it is saved only once.
  Future<void> postProgressUpdate(String contractId, {required String requestId, required String note});

  /// A fresh id for [postProgressUpdate].
  String newRequestId();

  /// Uploads one evidence photo to the contract's private folder and returns
  /// its storage path (allowed only while the worker's work is in progress).
  Future<String> uploadEvidence(String contractId, Uint8List bytes, {String contentType = 'image/jpeg'});

  /// A stored evidence photo's bytes, read with the signed-in party's
  /// access (no shareable download link is created).
  Future<Uint8List?> evidenceBytes(String path);
}

class ContractRemoteDataSourceImpl implements ContractRemoteDataSource {
  final FirebaseFirestore _firestore;

  ContractRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _contracts => _firestore.collection(FirestorePaths.contracts);

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

      // 1. A job assigned to this one worker (readable only by the two).
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc();
      batch.set(jobRef, {
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
        'status': 'assigned',
        'urgency': 'normal',
        'images': <String>[],
        'totalProposals': 0,
        'selectedWorkerId': workerId,
        'selectedWorkerName': workerName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. The pending contract (the worker accepts or declines it).
      final contractRef = _contracts.doc();
      const commissionRate = 0.10;
      final commissionAmount = totalAmount * commissionRate;
      batch.set(contractRef, {
        'jobId': jobRef.id,
        'jobTitle': 'Direct Hire: $categoryName',
        'jobDescription': 'Direct booking for $hours hour(s) of $categoryName work.',
        'estimatedDuration': '$hours h',
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
        'workerEarnings': totalAmount - commissionAmount,
        'paymentStatus': 'unpaid',
        'paymentProviderState': 'not_configured',
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
        'clientReviewed': false,
        'workerReviewed': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Tell the worker.
      batch.set(_firestore.collection(FirestorePaths.notifications).doc(), {
        'userId': workerId,
        'title': 'New Direct Booking',
        'body': 'You have received a new booking request from $clientName for $categoryName!',
        'type': 'booking',
        'referenceId': contractRef.id,
        'payload': {'contractId': contractRef.id, 'jobId': jobRef.id},
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
      });

      await batch.commit();
      return contractRef.id;
    } catch (e) {
      throw ServerException('Failed to create direct contract: $e');
    }
  }

  List<ContractModel> _list(QuerySnapshot<Map<String, dynamic>> s) => s.docs.map(ContractModel.fromSnapshot).toList();

  @override
  Stream<List<ContractModel>> getContractsByClient(String clientId) =>
      _contracts.where('clientId', isEqualTo: clientId).orderBy('createdAt', descending: true).snapshots().map(_list);

  @override
  Stream<List<ContractModel>> getContractsByWorker(String workerId) =>
      _contracts.where('workerId', isEqualTo: workerId).orderBy('createdAt', descending: true).snapshots().map(_list);

  @override
  Stream<ContractModel?> watchContract(String contractId) =>
      _contracts.doc(contractId).snapshots().map((d) => d.exists ? ContractModel.fromSnapshot(d) : null);

  @override
  Stream<ContractModel?> watchContractForJob(String jobId, {required String uid, required bool asClient}) => _contracts
      // The party filter is required by the rules (participants only).
      .where(asClient ? 'clientId' : 'workerId', isEqualTo: uid)
      .where('jobId', isEqualTo: jobId)
      .snapshots()
      .map((s) {
        final list = _list(s)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list.isEmpty ? null : list.first;
      });

  @override
  Stream<List<ContractUpdate>> watchUpdates(String contractId) => _contracts
      .doc(contractId)
      .collection('updates')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => [for (final d in s.docs) ContractUpdate.fromMap(d.id, d.data())]);

  @override
  Stream<List<ContractSubmission>> watchSubmissions(String contractId) =>
      _contracts.doc(contractId).collection('submissions').snapshots().map((s) {
        final list = [for (final d in s.docs) ContractSubmission.fromMap(d.id, d.data())];
        return list..sort((a, b) => a.number.compareTo(b.number));
      });
}

class ContractActionsImpl implements ContractActions {
  ContractActionsImpl(this._functions, this._storage);
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    final result = await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(result.data);
  }

  Future<void> _action(String contractId, String action, [Map<String, dynamic> extra = const {}]) =>
      _call('contractActionCall', {'contractId': contractId, 'action': action, ...extra});

  @override
  Future<String> acceptProposal(String proposalId) async =>
      (await _call('acceptProposalCall', {'proposalId': proposalId}))['contractId'] as String;

  @override
  Future<String?> respondToDirectRequest(String jobId, {required bool accept}) async =>
      (await _call('directRequestCall', {'jobId': jobId, 'accept': accept}))['contractId'] as String?;

  @override
  Future<void> respondToRequest(String contractId, {required bool accept}) => _action(contractId, 'respond', {'accept': accept});

  @override
  Future<void> startWork(String contractId) => _action(contractId, 'start');

  @override
  Future<void> submitWork(String contractId, {required String note, List<String> attachments = const []}) =>
      _action(contractId, 'submit', {'note': note, 'attachments': attachments});

  @override
  Future<void> confirmCompletion(String contractId) => _action(contractId, 'confirm');

  @override
  Future<void> cancel(String contractId, {required String reason, String note = ''}) =>
      _action(contractId, 'cancel', {'reason': reason, if (note.trim().isNotEmpty) 'note': note.trim()});

  @override
  Future<void> shareAddress(String contractId, String address) => _action(contractId, 'shareAddress', {'address': address});

  @override
  Future<void> requestRevision(String contractId, {required String note}) =>
      _action(contractId, 'requestRevision', {'note': note.trim()});

  @override
  Future<void> postProgressUpdate(String contractId, {required String requestId, required String note}) =>
      _action(contractId, 'progressUpdate', {'requestId': requestId, 'note': note.trim()});

  @override
  String newRequestId() => const Uuid().v4();

  @override
  Future<String> uploadEvidence(String contractId, Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final ext = contentType == 'image/png' ? 'png' : 'jpg';
    final path = 'contracts/$contractId/evidence/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _storage.ref(path).putData(bytes, SettableMetadata(contentType: contentType));
    return path;
  }

  @override
  Future<Uint8List?> evidenceBytes(String path) => _storage.ref(path).getData(5 * 1024 * 1024);
}

/// Job status that matches a contract status change (kept for reference and
/// tests; the contract functions apply the same mapping on the server).
String jobStatusForContractStatus(String contractStatus) => switch (contractStatus) {
      'active' => 'in_progress',
      'rejected' || 'cancelled' => 'cancelled',
      'completed' => 'completed',
      _ => 'assigned',
    };

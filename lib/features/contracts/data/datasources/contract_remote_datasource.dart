import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/media/private_media.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_transactions.dart';
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

/// Hiring and lifecycle steps. Free plan (Phase S4): Firestore transactions
/// whose every write is checked by the rules' contract state machine
/// (contract_transactions.dart; was functions/src/contracts.ts).
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
  /// Shares the exact address; [location] also pins the place on the map
  /// (the worker's navigation destination); [clearLocation] removes a pin.
  /// Neither leaves an existing pin as it is.
  Future<void> shareAddress(String contractId, String address, {LatLng? location, bool clearLocation = false});

  /// The client sends submitted work back with what to change (Phase 4B).
  Future<void> requestRevision(String contractId, {required String note});

  /// The hired worker posts a progress update. [requestId] is chosen once
  /// per update and reused on retry, so it is saved only once.
  Future<void> postProgressUpdate(String contractId, {required String requestId, required String note});

  /// A fresh id for [postProgressUpdate].
  String newRequestId();

  /// Stores one evidence photo privately for the contract and returns its
  /// path (allowed only while the worker's work is in progress).
  Future<String> uploadEvidence(String contractId, Uint8List bytes, {String contentType = 'image/jpeg'});

  /// A stored evidence photo's bytes, read with the signed-in party's
  /// access (there is no shareable link).
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
      // `{jobId}_{workerId}`, like every contract (the rules link them by it).
      final contractRef = _contracts.doc('${jobRef.id}_$workerId');
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
        // Server time: the notification rules require it (free plan, Phase S5).
        'createdAt': FieldValue.serverTimestamp(),
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
  ContractActionsImpl(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Free plan (Phase S4): the steps run as Firestore transactions checked
  /// by the rules (contract_transactions.dart), not Cloud Functions.
  ContractTransactions get _tx {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const ContractException(ContractFailure.notAllowed, 'Please sign in.');
    return ContractTransactions(_db, uid);
  }

  Future<T> _run<T>(Future<T> Function(ContractTransactions t) step) async {
    try {
      return await step(_tx);
    } on ContractStepException catch (e) {
      throw ContractException(switch (e.problem) {
        ContractStepProblem.notAllowed => ContractFailure.notAllowed,
        ContractStepProblem.wrongState => ContractFailure.wrongState,
        ContractStepProblem.invalid => ContractFailure.invalid,
      }, e.message);
    } on FirebaseException catch (e) {
      throw ContractException(contractFailureOf(e), e.message);
    }
  }

  @override
  Future<String> acceptProposal(String proposalId) => _run((t) => t.acceptProposal(proposalId));

  @override
  Future<String?> respondToDirectRequest(String jobId, {required bool accept}) =>
      _run((t) => t.respondToDirectRequest(jobId, accept: accept));

  @override
  Future<void> respondToRequest(String contractId, {required bool accept}) => _run((t) => t.respond(contractId, accept: accept));

  @override
  Future<void> startWork(String contractId) => _run((t) => t.start(contractId));

  @override
  Future<void> submitWork(String contractId, {required String note, List<String> attachments = const []}) =>
      _run((t) => t.submit(contractId, note: note, attachments: attachments));

  @override
  Future<void> confirmCompletion(String contractId) => _run((t) => t.confirm(contractId));

  @override
  Future<void> cancel(String contractId, {required String reason, String note = ''}) =>
      _run((t) => t.cancel(contractId, reason: reason, note: note));

  @override
  Future<void> shareAddress(String contractId, String address, {LatLng? location, bool clearLocation = false}) =>
      _run((t) => t.shareAddress(contractId, address,
          lat: location?.latitude, lng: location?.longitude, clearLocation: location == null && clearLocation));

  @override
  Future<void> requestRevision(String contractId, {required String note}) => _run((t) async {
        final r = await t.requestRevision(contractId, note: note);
        // Sent after the step (in-app only), so a refused notice never undoes it.
        await t.notifyAfter(r.workerId, 'Changes requested', '${r.name} asked for changes to "${r.title}".',
            'revision_requested', contractId, r.jobId);
      });

  @override
  Future<void> postProgressUpdate(String contractId, {required String requestId, required String note}) => _run((t) async {
        final r = await t.progressUpdate(contractId, requestId: requestId, note: note);
        if (r == null) return; // a retry: already saved
        final text = note.trim();
        await t.notifyAfter(r.clientId, 'Progress update',
            '${r.name}: ${text.length > 80 ? '${text.substring(0, 77)}…' : text}', 'progress_update', contractId, r.jobId);
      });

  @override
  String newRequestId() => const Uuid().v4();

  /// Free plan (Phase S6): kept privately in Firestore (the two parties and
  /// staff), at `contracts/{id}/evidence/{photo}`; the rules allow it only
  /// from the hired worker while the work is in progress.
  @override
  Future<String> uploadEvidence(String contractId, Uint8List bytes, {String contentType = 'image/jpeg'}) {
    final uid = _auth.currentUser?.uid ?? '';
    final type = privateImageTypes.contains(contentType) ? contentType : 'image/jpeg';
    return PrivateMedia.put(
      _db.collection(FirestorePaths.contracts).doc(contractId).collection('evidence')
          .doc('p${DateTime.now().millisecondsSinceEpoch}'),
      bytes,
      contentType: type,
      extra: {'uploadedBy': uid},
    );
  }

  @override
  Future<Uint8List?> evidenceBytes(String path) => PrivateMedia.read(_db, path);
}

/// Job status that matches a contract status change (kept for reference and
/// tests; the contract steps apply the same mapping).
String jobStatusForContractStatus(String contractStatus) => switch (contractStatus) {
      'active' => 'in_progress',
      'rejected' || 'cancelled' => 'cancelled',
      'completed' => 'completed',
      _ => 'assigned',
    };

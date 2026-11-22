import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_remote_datasource.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_activity.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_model.dart';

/// In-memory contracts for widget tests. Not Firebase: the trusted functions'
/// rules are tested in functions/test/contracts.test.js and rules-tests/.
class FakeContractStore implements ContractRemoteDataSource {
  FakeContractStore([Map<String, Map<String, dynamic>> initial = const {}]) {
    data.addAll({for (final e in initial.entries) e.key: Map<String, dynamic>.from(e.value)});
  }

  final Map<String, Map<String, dynamic>> data = {};

  /// Progress updates and submission history per contract (Phase 4B).
  final Map<String, List<ContractUpdate>> updates = {};
  final Map<String, List<ContractSubmission>> submissions = {};
  final _changes = StreamController<void>.broadcast();
  Object? failWith;

  void patch(String id, Map<String, dynamic> fields) {
    data[id] = {...data[id]!, ...fields};
    _changes.add(null);
  }

  void notify() => _changes.add(null);

  ContractModel _model(String id) => ContractModel.fromMap(id, data[id]!);

  Stream<T> _live<T>(T Function() read) async* {
    if (failWith != null) throw failWith!;
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<List<ContractModel>> getContractsByClient(String clientId) =>
      _live(() => [for (final id in data.keys) if (data[id]!['clientId'] == clientId) _model(id)]);

  @override
  Stream<List<ContractModel>> getContractsByWorker(String workerId) =>
      _live(() => [for (final id in data.keys) if (data[id]!['workerId'] == workerId) _model(id)]);

  @override
  Stream<ContractModel?> watchContract(String contractId) => _live(() => data.containsKey(contractId) ? _model(contractId) : null);

  @override
  Stream<ContractModel?> watchContractForJob(String jobId, {required String uid, required bool asClient}) => _live(() {
        for (final id in data.keys) {
          final d = data[id]!;
          if (d['jobId'] == jobId && d[asClient ? 'clientId' : 'workerId'] == uid) return _model(id);
        }
        return null;
      });

  @override
  Stream<List<ContractUpdate>> watchUpdates(String contractId) =>
      _live(() => [...?updates[contractId]]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Stream<List<ContractSubmission>> watchSubmissions(String contractId) =>
      _live(() => [...?submissions[contractId]]..sort((a, b) => a.number.compareTo(b.number)));

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
  }) =>
      throw UnimplementedError();
}

/// Records each lifecycle call and applies the same state change the server
/// would, so screens can be driven through a whole flow.
class FakeContractActions implements ContractActions {
  FakeContractActions(this.store);
  final FakeContractStore store;
  final List<String> calls = [];
  final List<Uint8List> uploads = [];
  Object? failWith;
  final _now = Timestamp.fromDate(DateTime(2026, 11, 10, 10));

  Future<void> _gate(String call) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
  }

  @override
  Future<String> acceptProposal(String proposalId) async {
    await _gate('accept:$proposalId');
    return proposalId;
  }

  @override
  Future<String?> respondToDirectRequest(String jobId, {required bool accept}) async {
    await _gate('direct:$jobId:$accept');
    return accept ? '${jobId}_w1' : null;
  }

  @override
  Future<void> respondToRequest(String contractId, {required bool accept}) async {
    await _gate('respond:$contractId:$accept');
    store.patch(contractId, {'status': accept ? 'active' : 'rejected', 'respondedAt': _now});
  }

  @override
  Future<void> startWork(String contractId) async {
    await _gate('start:$contractId');
    store.patch(contractId, {'workStartedAt': _now});
  }

  @override
  Future<void> submitWork(String contractId, {required String note, List<String> attachments = const []}) async {
    await _gate('submit:$contractId:$note:${attachments.join(',')}');
    final d = store.data[contractId]!;
    final n = ((d['submissionCount'] as int?) ?? (d['submittedAt'] != null ? 1 : 0)) + 1;
    store.patch(contractId, {'submittedAt': _now, 'submissionCount': n, 'submission': {'note': note, 'attachments': attachments}});
  }

  @override
  Future<void> requestRevision(String contractId, {required String note}) async {
    await _gate('revision:$contractId:$note');
    final d = store.data[contractId]!;
    store.patch(contractId, {
      'revisionCount': ((d['revisionCount'] as int?) ?? 0) + 1,
      'submissionCount': (d['submissionCount'] as int?) ?? 1,
      'revisionRequestedAt': _now,
      'revisionNote': note,
    });
  }

  int _ids = 0;
  final List<String> requestIds = [];

  @override
  String newRequestId() => 'req_test_${++_ids}';

  @override
  Future<void> postProgressUpdate(String contractId, {required String requestId, required String note}) async {
    requestIds.add(requestId);
    await _gate('update:$contractId:$requestId:$note');
    final list = store.updates.putIfAbsent(contractId, () => []);
    if (list.any((u) => u.id == requestId)) return; // same id: saved once
    list.add(ContractUpdate(id: requestId, note: note, authorId: 'w1', createdAt: _now.toDate()));
    store.notify();
  }

  @override
  Future<void> confirmCompletion(String contractId) async {
    await _gate('confirm:$contractId');
    store.patch(contractId, {'status': 'completed', 'completedAt': _now});
  }

  @override
  Future<void> cancel(String contractId, {required String reason, String note = ''}) async {
    await _gate('cancel:$contractId:$reason');
    store.patch(contractId, {'status': 'cancelled', 'cancelledAt': _now, 'cancelReason': reason, 'cancelledByRole': 'client'});
  }

  @override
  Future<void> shareAddress(String contractId, String address, {GeoCoord? location, bool clearLocation = false}) async {
    await _gate('address:$contractId:$address${location == null ? '' : ':${location.latitude},${location.longitude}'}');
    store.patch(contractId, {
      'serviceAddress': address,
      'addressSharedAt': _now,
      if (location != null) 'serviceLocation': GeoPoint(location.latitude, location.longitude),
      if (clearLocation) 'serviceLocation': null,
    });
  }

  @override
  Future<String> uploadEvidence(String contractId, Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    uploads.add(bytes);
    return 'contracts/$contractId/evidence/${uploads.length}.jpg';
  }

  /// Bytes returned for evidence photos (null: the read fails).
  Uint8List? evidence;
  final List<String> evidenceReads = [];

  @override
  Future<Uint8List?> evidenceBytes(String path) async {
    evidenceReads.add(path);
    if (evidence == null) throw Exception('no network in tests');
    return evidence;
  }
}

/// A contract document as the acceptProposalCall function writes it.
Map<String, dynamic> contractDoc({
  String jobId = 'j1',
  String workerId = 'w1',
  String clientId = 'client_1',
  String status = 'active',
  DateTime? started,
  DateTime? submitted,
  String proposalId = 'j1_w1',
  Map<String, dynamic> extra = const {},
}) =>
    {
      'jobId': jobId,
      'jobTitle': 'Fix two kitchen sockets',
      'jobDescription': 'Two sockets spark when plugged in.',
      'proposalId': proposalId,
      'clientId': clientId,
      'clientName': 'Ayesha Khan',
      'workerId': workerId,
      'workerName': 'Bilal Ahmed',
      'agreedRate': 2500,
      'rateType': 'fixed',
      'estimatedDuration': '1–2 days',
      'totalAmount': 2500,
      'commissionRate': 0.1,
      'commissionAmount': 250,
      'workerEarnings': 2250,
      'paymentStatus': 'unpaid',
      'serviceCity': 'Lahore',
      'serviceArea': 'Gulberg III',
      'status': status,
      'acceptedAt': Timestamp.fromDate(DateTime(2026, 11, 9, 9)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 9, 9)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 11, 9, 9)),
      'workStartedAt': started == null ? null : Timestamp.fromDate(started),
      'submittedAt': submitted == null ? null : Timestamp.fromDate(submitted),
      if (submitted != null) 'submission': {'note': 'Both sockets replaced and tested.', 'attachments': <String>[]},
      'clientReviewed': false,
      'workerReviewed': false,
      ...extra,
    };

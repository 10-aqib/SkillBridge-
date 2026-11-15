import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';

/// Hiring and the work lifecycle on the free Firebase plan (Phase S4).
///
/// With no Cloud Functions, each step runs here in one Firestore transaction,
/// and firestore.rules is the state machine that decides whether it's
/// allowed: who acts, at which stage, exactly which fields change and to what.
/// This mirrors functions/src/contracts.ts, and every write below has the
/// exact shape those rules check. Every contract id is `{jobId}_{workerId}`.

/// Commission taken on every contract (COMMISSION_RATE).
const contractCommissionRate = 0.1;

/// Revision rounds a client may ask for.
const maxContractRevisions = 3;

/// Evidence photos per submission.
const maxContractEvidence = 3;

/// Why a step was refused before anything was written.
enum ContractStepProblem { notAllowed, wrongState, invalid }

class ContractStepException implements Exception {
  const ContractStepException(this.problem, this.message);
  final ContractStepProblem problem;
  final String message;
  @override
  String toString() => 'ContractStepException($problem, $message)';
}

Never _fail(ContractStepProblem p, String message) => throw ContractStepException(p, message);

int _intOr(Object? v, int fallback) => v is int ? v : (v is num ? v.toInt() : fallback);

/// Submissions so far (older contracts: a set `submittedAt` counts as one).
int submissionsOf(Map<String, dynamic> c) {
  final n = c['submissionCount'];
  if (n is int) return n;
  return c['submittedAt'] != null ? 1 : 0;
}

int revisionsOf(Map<String, dynamic> c) => _intOr(c['revisionCount'], 0);

/// Stage of a contract, from stored fields (as stageOf in contracts.ts).
String contractStageOf(Map<String, dynamic> c) {
  switch (c['status']) {
    case 'pending':
      return 'requested';
    case 'completed':
      return 'completed';
    case 'cancelled':
      return 'cancelled';
    case 'rejected':
      return 'rejected';
    case 'active':
      if (submissionsOf(c) > revisionsOf(c)) return 'submitted';
      if (c['workStartedAt'] != null) return 'in_progress';
      return 'not_started';
    default:
      return 'unknown';
  }
}

String _text(Object? v, int min, int max, String field) {
  final s = v is String ? v.trim() : '';
  if (s.length < min || s.length > max) _fail(ContractStepProblem.invalid, '$field must be $min–$max characters.');
  return s;
}

/// The commission and the worker's share for [amount] (whole rupees).
({num commission, num earnings}) splitAmount(num amount) {
  final commission = (amount * contractCommissionRate).round();
  return (commission: commission, earnings: amount - commission);
}

/// Runs contract steps for the signed-in user [uid].
class ContractTransactions {
  ContractTransactions(this._db, this._uid);
  final FirebaseFirestore _db;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _contracts => _db.collection(FirestorePaths.contracts);
  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection(FirestorePaths.jobs);
  CollectionReference<Map<String, dynamic>> get _proposals => _db.collection(FirestorePaths.proposals);
  CollectionReference<Map<String, dynamic>> get _users => _db.collection(FirestorePaths.users);

  FieldValue get _now => FieldValue.serverTimestamp();

  Map<String, dynamic> _notification(String userId, String title, String body, String type, String contractId, String jobId) => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'payload': {'contractId': contractId, 'jobId': jobId},
        'referenceId': contractId,
        'isRead': false,
        'createdAt': _now,
      };

  void _notify(Transaction tx, String userId, String title, String body, String type, String contractId, String jobId) =>
      tx.set(_db.collection(FirestorePaths.notifications).doc(), _notification(userId, title, body, type, contractId, jobId));

  Future<Map<String, dynamic>> _activeMe(Transaction tx) async {
    final me = (await tx.get(_users.doc(_uid))).data();
    if (me == null) _fail(ContractStepProblem.notAllowed, 'No profile for this account.');
    if (me['isActive'] == false) _fail(ContractStepProblem.notAllowed, 'This account is suspended.');
    return me;
  }

  // ── Accept a proposal (creates the contract) ─────────────────────────────

  /// The job owner accepts a pending proposal on their public open job: the
  /// proposal accepted, the job assigned, the other pending proposals closed
  /// as "filled", the contract created at `contracts/{proposalId}`, the worker
  /// told. Repeating it returns the same contract.
  Future<String> acceptProposal(String proposalId) async {
    if (proposalId.isEmpty) _fail(ContractStepProblem.invalid, 'proposalId is required.');
    final pSnap = await _proposals.doc(proposalId).get();
    final p0 = pSnap.data();
    if (p0 == null) _fail(ContractStepProblem.notAllowed, 'Proposal not found.');
    final jobId = p0['jobId'] as String? ?? '';
    // Other applicants to close in the same write (read just before; the
    // rules stop new proposals once the job is assigned).
    final others = await _proposals
        .where('jobId', isEqualTo: jobId)
        .where('clientId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .get();

    return _db.runTransaction((tx) async {
      final pRef = _proposals.doc(proposalId);
      final p = (await tx.get(pRef)).data();
      if (p == null) _fail(ContractStepProblem.notAllowed, 'Proposal not found.');
      if (p['clientId'] != _uid) _fail(ContractStepProblem.notAllowed, 'Only the job owner can accept this proposal.');
      if (p['status'] == 'accepted') return proposalId; // already hired: same contract
      if (p['status'] != 'pending') _fail(ContractStepProblem.wrongState, 'This proposal is no longer pending.');
      final workerId = p['workerId'] as String? ?? '';
      if (proposalId != '${p['jobId']}_$workerId') _fail(ContractStepProblem.wrongState, 'Proposal does not belong to this job.');

      final jobRef = _jobs.doc(jobId);
      final job = (await tx.get(jobRef)).data();
      if (job == null) _fail(ContractStepProblem.notAllowed, 'Job not found.');
      if (job['clientId'] != _uid) _fail(ContractStepProblem.notAllowed, 'Only the job owner can accept proposals.');
      if (job['status'] != 'open' || job['selectedWorkerId'] != null) {
        _fail(ContractStepProblem.wrongState, 'This job is no longer open.');
      }
      final me = await _activeMe(tx);
      if (me['role'] != 'client') _fail(ContractStepProblem.notAllowed, 'Only clients can hire.');

      final rate = p['proposedRate'] as num? ?? 0;
      final split = splitAmount(rate);
      final clientName = (me['displayName'] as String?)?.isNotEmpty == true
          ? me['displayName'] as String
          : (job['clientName'] as String? ?? '');
      final clientPhoto = me['photoUrl'] as String? ?? job['clientPhotoUrl'] as String?;
      final workerName = p['workerName'] as String? ?? '';
      final title = job['title'] as String? ?? '';

      tx.update(pRef, {'status': 'accepted', 'decidedAt': _now, 'updatedAt': _now});
      tx.update(jobRef, {'status': 'assigned', 'selectedWorkerId': workerId, 'selectedWorkerName': workerName, 'updatedAt': _now});
      for (final d in others.docs) {
        if (d.id == proposalId) continue;
        tx.update(d.reference, {
          'status': 'rejected', 'closedReason': 'filled', 'decidedAt': _now, 'updatedAt': _now, 'jobStatus': 'assigned',
        });
      }
      tx.set(_contracts.doc(proposalId), {
        'jobId': jobId,
        'jobTitle': title,
        'jobDescription': job['description'] ?? '',
        'proposalId': proposalId,
        'clientId': _uid,
        'clientName': clientName,
        'clientPhotoUrl': clientPhoto,
        'workerId': workerId,
        'workerName': workerName,
        'workerPhotoUrl': p['workerPhotoUrl'],
        'agreedRate': rate,
        'rateType': p['rateType'] ?? 'fixed',
        'estimatedDuration': p['estimatedDuration'] ?? '',
        'totalAmount': rate,
        'commissionRate': contractCommissionRate,
        'commissionAmount': split.commission,
        'workerEarnings': split.earnings,
        'paymentStatus': 'unpaid',
        'paymentProviderState': 'not_configured',
        'serviceCity': job['city'],
        'serviceArea': job['address'],
        'status': 'active',
        'acceptedAt': _now,
        'startDate': _now,
        'workStartedAt': null,
        'submittedAt': null,
        'completedAt': null,
        'cancelledAt': null,
        'clientReviewed': false,
        'workerReviewed': false,
        'createdAt': _now,
        'updatedAt': _now,
      });
      _notify(tx, workerId, 'Proposal accepted',
          '${clientName.isEmpty ? 'The client' : clientName} hired you for "$title". Your contract is ready.',
          'contract_created', proposalId, jobId);
      return proposalId;
    });
  }

  // ── Direct requests (an open job sent to one worker) ────────────────────

  /// The requested worker answers. Accepting assigns the job and creates the
  /// contract `{jobId}_{worker}` at the client's budget (a range stays a
  /// range). Declining cancels the job. Returns the contract id, or null.
  Future<String?> respondToDirectRequest(String jobId, {required bool accept}) {
    if (jobId.isEmpty) _fail(ContractStepProblem.invalid, 'jobId is required.');
    final contractId = '${jobId}_$_uid';
    return _db.runTransaction((tx) async {
      final jobRef = _jobs.doc(jobId);
      final job = (await tx.get(jobRef)).data();
      if (job == null) _fail(ContractStepProblem.notAllowed, 'Job not found.');
      if (job['selectedWorkerId'] != _uid) _fail(ContractStepProblem.notAllowed, 'This request was not sent to you.');
      if (accept && (job['status'] == 'assigned' || job['status'] == 'in_progress')) return contractId; // answered
      if (job['status'] != 'open') _fail(ContractStepProblem.wrongState, 'This request was already answered or closed.');
      final me = await _activeMe(tx);
      if (me['role'] != 'worker') _fail(ContractStepProblem.notAllowed, 'Only workers answer requests.');
      final clientId = job['clientId'] as String;
      final title = (job['title'] as String?)?.isNotEmpty == true ? job['title'] as String : 'your job';
      final workerName = (me['displayName'] as String?)?.isNotEmpty == true
          ? me['displayName'] as String
          : (job['selectedWorkerName'] as String? ?? '');

      if (!accept) {
        tx.update(jobRef, {'status': 'cancelled', 'updatedAt': _now});
        tx.set(_db.collection(FirestorePaths.notifications).doc(), _notification(clientId, 'Request declined',
            '${workerName.isEmpty ? 'The worker' : workerName} declined "$title".', 'request_declined', '', jobId));
        return null;
      }

      final max = job['budgetMax'] as num? ?? 0;
      final min = job['budgetMin'] as num? ?? max;
      final split = splitAmount(max);
      tx.update(jobRef, {'status': 'assigned', 'selectedWorkerName': workerName, 'updatedAt': _now});
      tx.set(_contracts.doc(contractId), {
        'jobId': jobId,
        'jobTitle': job['title'] ?? '',
        'jobDescription': job['description'] ?? '',
        'proposalId': 'direct_request',
        'clientId': clientId,
        'clientName': job['clientName'] ?? '',
        'clientPhotoUrl': job['clientPhotoUrl'],
        'workerId': _uid,
        'workerName': workerName,
        'workerPhotoUrl': me['photoUrl'],
        'agreedRate': max,
        // The client's budget was a range: the final price is agreed in chat.
        'priceMin': min < max ? min : null,
        'rateType': job['budgetType'] ?? 'fixed',
        'estimatedDuration': '',
        'totalAmount': max,
        'commissionRate': contractCommissionRate,
        'commissionAmount': split.commission,
        'workerEarnings': split.earnings,
        'paymentStatus': 'unpaid',
        'paymentProviderState': 'not_configured',
        'serviceCity': job['city'],
        'serviceArea': job['address'],
        'status': 'active',
        'acceptedAt': _now,
        'startDate': _now,
        'workStartedAt': null,
        'submittedAt': null,
        'completedAt': null,
        'cancelledAt': null,
        'clientReviewed': false,
        'workerReviewed': false,
        'createdAt': _now,
        'updatedAt': _now,
      });
      tx.set(_db.collection(FirestorePaths.notifications).doc(), _notification(clientId, 'Request accepted',
          '${workerName.isEmpty ? 'The worker' : workerName} accepted "$title". Your contract is ready.',
          'contract_created', contractId, jobId));
      return contractId;
    });
  }

  // ── Lifecycle steps ──────────────────────────────────────────────────────

  /// Loads the contract and the job for one step and checks the caller is a
  /// party with an active account.
  Future<_Step> _load(Transaction tx, String contractId) async {
    if (contractId.isEmpty) _fail(ContractStepProblem.invalid, 'contractId is required.');
    final ref = _contracts.doc(contractId);
    final c = (await tx.get(ref)).data();
    if (c == null) _fail(ContractStepProblem.notAllowed, 'Contract not found.');
    final isClient = c['clientId'] == _uid;
    final isWorker = c['workerId'] == _uid;
    if (!isClient && !isWorker) _fail(ContractStepProblem.notAllowed, 'You are not part of this contract.');
    await _activeMe(tx);
    final jobId = c['jobId'] as String? ?? '';
    final jobRef = _jobs.doc(jobId);
    final job = jobId.isEmpty ? null : (await tx.get(jobRef)).data();
    return _Step(ref, c, isClient, isWorker, jobRef, job);
  }

  void _jobTo(Transaction tx, _Step s, String status) {
    if (s.job != null && s.job!['status'] != status) tx.update(s.jobRef, {'status': status, 'updatedAt': _now});
  }

  void _endLiveLocation(Transaction tx, _Step s) => tx.delete(s.ref.collection('live').doc('location'));

  /// The other party's notification for a step.
  void _tell(Transaction tx, _Step s, String title, String body, String type) {
    final other = s.isClient ? s.c['workerId'] as String : s.c['clientId'] as String;
    _notify(tx, other, title, body, type, s.ref.id, s.c['jobId'] as String? ?? '');
  }

  String _myName(_Step s) => s.isClient
      ? ((s.c['clientName'] as String?)?.isNotEmpty == true ? s.c['clientName'] as String : 'The client')
      : ((s.c['workerName'] as String?)?.isNotEmpty == true ? s.c['workerName'] as String : 'The worker');

  String _title(_Step s) => (s.c['jobTitle'] as String?)?.isNotEmpty == true ? s.c['jobTitle'] as String : 'your job';

  /// The worker accepts or declines a booking request.
  Future<void> respond(String contractId, {required bool accept}) => _db.runTransaction((tx) async {
        final s = await _load(tx, contractId);
        if (!s.isWorker) _fail(ContractStepProblem.notAllowed, 'Only the worker can answer a booking request.');
        if (s.stage != 'requested') _fail(ContractStepProblem.wrongState, 'This request was already answered.');
        if (accept) {
          tx.update(s.ref, {
            'status': 'active', 'respondedAt': _now, 'acceptedAt': _now,
            'workStartedAt': null, 'submittedAt': null, 'updatedAt': _now,
          });
          _jobTo(tx, s, 'assigned');
          _tell(tx, s, 'Booking accepted', '${_myName(s)} accepted your booking for "${_title(s)}".', 'booking_accepted');
          return;
        }
        tx.update(s.ref, {'status': 'rejected', 'respondedAt': _now, 'updatedAt': _now});
        _jobTo(tx, s, 'cancelled');
        _endLiveLocation(tx, s);
        _tell(tx, s, 'Booking declined', '${_myName(s)} declined your booking for "${_title(s)}".', 'booking_declined');
      });

  /// The hired worker starts the work, once.
  Future<void> start(String contractId) => _db.runTransaction((tx) async {
        final s = await _load(tx, contractId);
        if (!s.isWorker) _fail(ContractStepProblem.notAllowed, 'Only the hired worker can start work.');
        if (s.stage != 'not_started') _fail(ContractStepProblem.wrongState, "Work can't be started now.");
        if (s.job == null || s.job!['selectedWorkerId'] != _uid || s.job!['status'] != 'assigned') {
          _fail(ContractStepProblem.wrongState, 'The job is not assigned to you.');
        }
        tx.update(s.ref, {'workStartedAt': _now, 'updatedAt': _now});
        _jobTo(tx, s, 'in_progress');
        _tell(tx, s, 'Work started', '${_myName(s)} started work on "${_title(s)}".', 'work_started');
      });

  /// The hired worker submits the work (after starting). Every submission is
  /// kept in submissions/{number}; `submission` mirrors the latest.
  Future<void> submit(String contractId, {required String note, List<String> attachments = const []}) {
    final text = _text(note, 10, 1000, 'Note');
    if (attachments.length > maxContractEvidence) _fail(ContractStepProblem.invalid, 'Up to $maxContractEvidence photos.');
    final photos = attachments.toSet().toList();
    return _db.runTransaction((tx) async {
      final s = await _load(tx, contractId);
      if (!s.isWorker) _fail(ContractStepProblem.notAllowed, 'Only the hired worker can submit work.');
      if (s.stage == 'submitted') _fail(ContractStepProblem.wrongState, 'Work was already submitted.');
      if (s.stage != 'in_progress') _fail(ContractStepProblem.wrongState, 'Start the work before submitting it.');
      final number = submissionsOf(s.c) + 1;
      tx.set(s.ref.collection('submissions').doc('$number'), {
        'number': number, 'note': text, 'attachments': photos, 'submittedAt': _now, 'submittedBy': _uid,
      });
      tx.update(s.ref, {
        'submittedAt': _now,
        'submission': {'note': text, 'attachments': photos, 'submittedAt': _now},
        'submissionCount': number,
        'updatedAt': _now,
      });
      _endLiveLocation(tx, s);
      _tell(tx, s, number > 1 ? 'Work resubmitted' : 'Work submitted',
          '${_myName(s)} ${number > 1 ? 'resubmitted' : 'submitted'} "${_title(s)}" for your review.', 'work_submitted');
    });
  }

  /// The client confirms submitted work. The worker's completed-jobs count
  /// goes up once, naming this contract (the rules allow exactly that).
  Future<void> confirm(String contractId) => _db.runTransaction((tx) async {
        final s = await _load(tx, contractId);
        if (!s.isClient) _fail(ContractStepProblem.notAllowed, 'Only the client can confirm completion.');
        if (s.stage != 'submitted') _fail(ContractStepProblem.wrongState, 'There is no submitted work to confirm.');
        tx.update(s.ref, {'status': 'completed', 'completedAt': _now, 'endDate': _now, 'updatedAt': _now});
        _jobTo(tx, s, 'completed');
        _endLiveLocation(tx, s);
        tx.update(_users.doc(s.c['workerId'] as String), {
          'workerProfile.totalJobsCompleted': FieldValue.increment(1),
          'lastCompletedContractId': contractId,
        });
        _tell(tx, s, 'Completion confirmed', '${_myName(s)} confirmed "${_title(s)}" is complete.', 'completion_confirmed');
      });

  /// Either party cancels, before the work is submitted.
  Future<void> cancel(String contractId, {required String reason, String note = ''}) {
    const reasons = ['schedule_conflict', 'no_longer_needed', 'agreed_with_other_party', 'safety_concern', 'other'];
    if (!reasons.contains(reason)) _fail(ContractStepProblem.invalid, 'Choose a reason.');
    final text = note.trim().isEmpty ? '' : _text(note, 1, 300, 'Note');
    return _db.runTransaction((tx) async {
      final s = await _load(tx, contractId);
      if (!const ['requested', 'not_started', 'in_progress'].contains(s.stage)) {
        _fail(ContractStepProblem.wrongState, s.stage == 'submitted'
            ? 'Submitted work can only be confirmed by the client.'
            : 'This contract can no longer be cancelled.');
      }
      tx.update(s.ref, {
        'status': 'cancelled', 'cancelledAt': _now, 'cancelledBy': _uid,
        'cancelledByRole': s.isClient ? 'client' : 'worker', 'cancelReason': reason, 'cancelNote': text,
        'updatedAt': _now,
      });
      _jobTo(tx, s, 'cancelled');
      _endLiveLocation(tx, s);
      _tell(tx, s, 'Contract cancelled', '${_myName(s)} cancelled the contract for "${_title(s)}".', 'contract_cancelled');
    });
  }

  /// The client shares the exact address, optionally pinning the place on
  /// the map ([lat]/[lng]) or removing a pin ([clearLocation]).
  Future<void> shareAddress(String contractId, String address, {double? lat, double? lng, bool clearLocation = false}) {
    final text = _text(address, 5, 200, 'Address');
    if (lat != null || lng != null) {
      final ok = lat != null && lng != null && lat.isFinite && lng.isFinite &&
          lat.abs() <= 90 && lng.abs() <= 180 && !(lat == 0 && lng == 0);
      if (!ok) _fail(ContractStepProblem.invalid, 'Location must be a valid map position.');
    }
    return _db.runTransaction((tx) async {
      final s = await _load(tx, contractId);
      if (!s.isClient) _fail(ContractStepProblem.notAllowed, 'Only the client can share the address.');
      if (!const ['requested', 'not_started', 'in_progress'].contains(s.stage)) {
        _fail(ContractStepProblem.wrongState, 'The contract is closed.');
      }
      tx.update(s.ref, {
        'serviceAddress': text,
        'addressSharedAt': _now,
        'updatedAt': _now,
        if (lat != null && lng != null) ...{'serviceLocation': GeoPoint(lat, lng), 'serviceLocationSetAt': _now}
        else if (clearLocation) ...{'serviceLocation': FieldValue.delete(), 'serviceLocationSetAt': FieldValue.delete()},
      });
      _tell(tx, s, 'Address shared', '${_myName(s)} shared the exact address for "${_title(s)}".', 'address_shared');
    });
  }

  /// The client sends submitted work back (at most [maxContractRevisions]
  /// times). Returns the worker's id and the job id for the notification.
  Future<({String workerId, String jobId, String name, String title})> requestRevision(String contractId, {required String note}) {
    final text = _text(note, 10, 1000, 'Note');
    return _db.runTransaction((tx) async {
      final s = await _load(tx, contractId);
      if (!s.isClient) _fail(ContractStepProblem.notAllowed, 'Only the client can ask for changes.');
      if (s.stage != 'submitted') _fail(ContractStepProblem.wrongState, 'There is no submitted work to send back.');
      final rounds = revisionsOf(s.c);
      if (rounds >= maxContractRevisions) {
        _fail(ContractStepProblem.wrongState, 'No more revision rounds are left. Confirm the work or contact support.');
      }
      final number = submissionsOf(s.c);
      tx.update(s.ref, {
        'revisionCount': rounds + 1, 'revisionRequestedAt': _now, 'revisionNote': text,
        'submissionCount': number, 'updatedAt': _now,
      });
      final legacy = s.c['submissionCount'] is! int;
      final latest = s.c['submission'] is Map ? Map<String, dynamic>.from(s.c['submission'] as Map) : const <String, dynamic>{};
      tx.set(s.ref.collection('submissions').doc('$number'), {
        'number': number, 'revisionNote': text, 'revisionRequestedAt': _now,
        if (legacy) ...{
          'note': latest['note'] ?? '',
          'attachments': latest['attachments'] ?? const <String>[],
          'submittedAt': s.c['submittedAt'],
        },
      }, SetOptions(merge: true));
      return (workerId: s.c['workerId'] as String, jobId: s.c['jobId'] as String? ?? '', name: _myName(s), title: _title(s));
    });
  }

  /// The hired worker posts a progress update; [requestId] makes a retry a
  /// no-op. Returns null when it was already saved.
  Future<({String clientId, String jobId, String name})?> progressUpdate(String contractId,
      {required String requestId, required String note}) {
    if (!RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(requestId)) _fail(ContractStepProblem.invalid, 'requestId is required.');
    final text = _text(note, 2, 1000, 'Update');
    return _db.runTransaction((tx) async {
      final s = await _load(tx, contractId);
      if (!s.isWorker) _fail(ContractStepProblem.notAllowed, 'Only the hired worker posts progress updates.');
      if (!const ['not_started', 'in_progress'].contains(s.stage)) {
        _fail(ContractStepProblem.wrongState, 'Updates can be posted only while the work is open.');
      }
      final updateRef = s.ref.collection('updates').doc(requestId);
      if ((await tx.get(updateRef)).exists) return null; // retry: already saved
      tx.set(updateRef, {'note': text, 'authorId': _uid, 'authorRole': 'worker', 'createdAt': _now});
      tx.update(s.ref, {
        'lastUpdateAt': _now, 'updateCount': FieldValue.increment(1), 'lastUpdateId': requestId, 'updatedAt': _now,
      });
      return (clientId: s.c['clientId'] as String, jobId: s.c['jobId'] as String? ?? '', name: _myName(s));
    });
  }

  /// A notification sent after a step, best effort: the step has already
  /// happened, so a refused or failed notification never undoes it.
  Future<void> notifyAfter(String userId, String title, String body, String type, String contractId, String jobId) async {
    try {
      await _db.collection(FirestorePaths.notifications).add(_notification(userId, title, body, type, contractId, jobId));
    } catch (_) {
      // In-app notification only; nothing to undo.
    }
  }
}

class _Step {
  _Step(this.ref, this.c, this.isClient, this.isWorker, this.jobRef, this.job);
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> c;
  final bool isClient;
  final bool isWorker;
  final DocumentReference<Map<String, dynamic>> jobRef;
  final Map<String, dynamic>? job;
  String get stage => contractStageOf(c);
}

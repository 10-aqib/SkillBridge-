import 'dart:async';

import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/proposals/data/datasources/proposal_remote_datasource.dart';
import 'package:skill_bridge/features/proposals/data/models/proposal_model.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';

/// In-memory proposals for widget tests. Not Firebase: it records what the
/// screens ask for and applies the same state changes the rules allow, so a
/// screen can be driven through a whole flow.
class FakeProposalDataSource implements ProposalRemoteDataSource {
  FakeProposalDataSource([Iterable<ProposalModel> initial = const []]) {
    for (final p in initial) {
      store[p.id] = p;
    }
  }

  final Map<String, ProposalModel> store = {};
  final _changes = StreamController<void>.broadcast();

  final List<ProposalModel> submitted = [];
  final List<String> withdrawn = [];
  final List<String> viewed = [];
  final List<String> rejected = [];
  final List<(String proposalId, String jobId)> accepted = [];

  /// When set, the next write waits for it (to test "sending" states).
  Completer<void>? hold;

  /// When set, writes fail with it.
  Object? failWith;

  Future<void> _gate() async {
    if (hold != null) await hold!.future;
    if (failWith != null) throw failWith!;
  }

  void _put(ProposalModel p) {
    store[p.id] = p;
    _changes.add(null);
  }

  ProposalModel _with(ProposalModel p, {required ProposalStatus status, DateTime? viewedAt, DateTime? decidedAt, DateTime? withdrawnAt, String? closedReason}) =>
      ProposalModel(
        id: p.id,
        jobId: p.jobId,
        jobTitle: p.jobTitle,
        workerId: p.workerId,
        workerName: p.workerName,
        workerPhotoUrl: p.workerPhotoUrl,
        coverLetter: p.coverLetter,
        proposedRate: p.proposedRate,
        rateType: p.rateType,
        estimatedDuration: p.estimatedDuration,
        status: status,
        clientId: p.clientId,
        createdAt: p.createdAt,
        updatedAt: DateTime(2026, 11, 9),
        viewedAt: viewedAt ?? p.viewedAt,
        decidedAt: decidedAt ?? p.decidedAt,
        withdrawnAt: withdrawnAt ?? p.withdrawnAt,
        closedReason: closedReason ?? p.closedReason,
      );

  @override
  Future<String> submitProposal(ProposalModel proposal, {ProposalEntity? existing}) async {
    submitted.add(proposal);
    await _gate();
    final id = ProposalEntity.idFor(proposal.jobId, proposal.workerId);
    final current = store[id];
    if (current != null && current.status != ProposalStatus.withdrawn) {
      throw const ProposalException(ProposalFailure.alreadySent);
    }
    _put(ProposalModel(
      id: id,
      jobId: proposal.jobId,
      jobTitle: proposal.jobTitle,
      workerId: proposal.workerId,
      workerName: proposal.workerName,
      workerPhotoUrl: proposal.workerPhotoUrl,
      coverLetter: proposal.coverLetter,
      proposedRate: proposal.proposedRate,
      rateType: proposal.rateType,
      estimatedDuration: proposal.estimatedDuration,
      status: ProposalStatus.pending,
      clientId: proposal.clientId,
      createdAt: current?.createdAt ?? DateTime(2026, 11, 9),
      updatedAt: DateTime(2026, 11, 9),
    ));
    return id;
  }

  @override
  Future<void> withdrawProposal(String proposalId) async {
    withdrawn.add(proposalId);
    await _gate();
    _put(_with(store[proposalId]!, status: ProposalStatus.withdrawn, withdrawnAt: DateTime(2026, 11, 9)));
  }

  @override
  Future<void> markViewed(String proposalId) async {
    viewed.add(proposalId);
    await _gate();
    _put(_with(store[proposalId]!, status: store[proposalId]!.status, viewedAt: DateTime(2026, 11, 9)));
  }

  @override
  Future<void> rejectProposal(String proposalId) async {
    rejected.add(proposalId);
    await _gate();
    _put(_with(store[proposalId]!, status: ProposalStatus.rejected, decidedAt: DateTime(2026, 11, 9), closedReason: 'client'));
  }

  @override
  Future<String> acceptProposal({required ProposalEntity proposal, required JobEntity job, required String clientName, String? clientPhotoUrl}) async {
    accepted.add((proposal.id, job.id));
    await _gate();
    for (final p in store.values.toList()) {
      if (p.jobId != job.id) continue;
      if (p.id == proposal.id) {
        _put(_with(p, status: ProposalStatus.accepted, decidedAt: DateTime(2026, 11, 9)));
      } else if (p.status == ProposalStatus.pending) {
        _put(_with(p, status: ProposalStatus.rejected, decidedAt: DateTime(2026, 11, 9), closedReason: 'filled'));
      }
    }
    return proposal.id;
  }

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<List<ProposalModel>> getProposalsForJob(String jobId, String clientId) =>
      _live(() => store.values.where((p) => p.jobId == jobId && p.clientId == clientId).toList());

  @override
  Stream<List<ProposalModel>> getProposalsByWorker(String workerId) => _live(() {
        final list = store.values.where((p) => p.workerId == workerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  @override
  Stream<ProposalModel?> watchProposal(String proposalId) => _live(() => store[proposalId]);
}

ProposalModel testProposal(
  String jobId,
  String workerId, {
  String clientId = 'client_1',
  String jobTitle = 'Fix two kitchen sockets',
  String workerName = 'Bilal Ahmed',
  double rate = 2500,
  String rateType = 'fixed',
  String duration = '1–2 days',
  String cover = 'I have fixed many sparking sockets and carry a tester and spare parts.',
  ProposalStatus status = ProposalStatus.pending,
  DateTime? createdAt,
  DateTime? viewedAt,
  String? closedReason,
  JobStatus? jobStatus,
}) =>
    ProposalModel(
      id: ProposalEntity.idFor(jobId, workerId),
      jobId: jobId,
      jobTitle: jobTitle,
      workerId: workerId,
      workerName: workerName,
      coverLetter: cover,
      proposedRate: rate,
      rateType: rateType,
      estimatedDuration: duration,
      status: status,
      clientId: clientId,
      createdAt: createdAt ?? DateTime(2026, 11, 5),
      updatedAt: createdAt ?? DateTime(2026, 11, 5),
      viewedAt: viewedAt,
      closedReason: closedReason,
      jobStatus: jobStatus,
    );

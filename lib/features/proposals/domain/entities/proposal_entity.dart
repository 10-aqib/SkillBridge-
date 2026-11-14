import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';

class ProposalEntity {
  final String id;
  final String jobId;
  final String jobTitle;
  final String workerId;
  final String workerName;
  final String? workerPhotoUrl;

  /// Legacy field written by older app versions. Not trusted or shown:
  /// ratings are read from the worker's profile (review-derived).
  final double workerRating;
  final String coverLetter;
  final double proposedRate;
  final String rateType; // "hourly", "daily", "fixed"
  final String estimatedDuration;
  final ProposalStatus status;
  final String clientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When the client first opened it (shown to the worker as "Viewed").
  final DateTime? viewedAt;

  /// When the client accepted or declined it.
  final DateTime? decidedAt;
  final DateTime? withdrawnAt;

  /// Why a proposal was closed: 'client' (declined) or 'filled' (someone
  /// else was hired).
  final String? closedReason;

  /// The job's status, copied by a trusted function. Applicants follow the
  /// job through this once it is no longer public: they cannot read the job
  /// itself then, since it names the hired worker. Null until first copied
  /// (a proposal can only be sent to an open job).
  final JobStatus? jobStatus;

  const ProposalEntity({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.workerId,
    required this.workerName,
    this.workerPhotoUrl,
    required this.workerRating,
    required this.coverLetter,
    required this.proposedRate,
    required this.rateType,
    required this.estimatedDuration,
    required this.status,
    required this.clientId,
    required this.createdAt,
    required this.updatedAt,
    this.viewedAt,
    this.decidedAt,
    this.withdrawnAt,
    this.closedReason,
    this.jobStatus,
  });

  /// Fixed document id: one proposal per worker per job.
  static String idFor(String jobId, String workerId) => '${jobId}_$workerId';

  bool get isActive => status == ProposalStatus.pending;
  bool get wasViewed => viewedAt != null;
  /// Best known job status: the live job when readable, else the copy.
  JobStatus jobStatusOr(JobStatus? live) => live ?? jobStatus ?? JobStatus.open;

  bool get closedBecauseFilled => status == ProposalStatus.rejected && closedReason == 'filled';
}

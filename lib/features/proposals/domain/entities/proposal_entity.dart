import 'package:skill_bridge/core/enums/proposal_status.dart';

class ProposalEntity {
  final String id;
  final String jobId;
  final String jobTitle;
  final String workerId;
  final String workerName;
  final String? workerPhotoUrl;
  final double workerRating;
  final String coverLetter;
  final double proposedRate;
  final String rateType; // "hourly", "daily", "fixed"
  final String estimatedDuration;
  final ProposalStatus status;
  final String clientId;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  });
}

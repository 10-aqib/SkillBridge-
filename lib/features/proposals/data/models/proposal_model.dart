import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';

class ProposalModel extends ProposalEntity {
  const ProposalModel({
    required super.id,
    required super.jobId,
    required super.jobTitle,
    required super.workerId,
    required super.workerName,
    super.workerPhotoUrl,
    super.workerRating = 0,
    required super.coverLetter,
    required super.proposedRate,
    required super.rateType,
    required super.estimatedDuration,
    required super.status,
    required super.clientId,
    required super.createdAt,
    required super.updatedAt,
    super.viewedAt,
    super.decidedAt,
    super.withdrawnAt,
    super.closedReason,
    super.jobStatus,
  });

  factory ProposalModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProposalModel.fromMap(doc.id, data);
  }

  factory ProposalModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? ts(String k) => (data[k] as Timestamp?)?.toDate();
    return ProposalModel(
      id: id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      workerId: data['workerId'] ?? '',
      workerName: data['workerName'] ?? '',
      workerPhotoUrl: data['workerPhotoUrl'],
      workerRating: (data['workerRating'] ?? 0.0).toDouble(),
      coverLetter: data['coverLetter'] ?? '',
      proposedRate: (data['proposedRate'] ?? 0.0).toDouble(),
      rateType: data['rateType'] ?? 'fixed',
      estimatedDuration: data['estimatedDuration'] ?? '',
      status: ProposalStatus.values.firstWhere(
        (e) => e.name == data['status'] || e.value == data['status'],
        orElse: () => ProposalStatus.pending,
      ),
      clientId: data['clientId'] ?? '',
      createdAt: ts('createdAt') ?? DateTime.now(),
      updatedAt: ts('updatedAt') ?? DateTime.now(),
      viewedAt: ts('viewedAt'),
      decidedAt: ts('decidedAt'),
      withdrawnAt: ts('withdrawnAt'),
      closedReason: data['closedReason'] as String?,
      jobStatus: data['jobStatus'] is String ? JobStatus.fromString(data['jobStatus'] as String) : null,
    );
  }

  /// A new proposal. Status, timestamps and ownership are fixed here and
  /// checked again by the rules; no rating or decision fields are sent.
  Map<String, dynamic> toCreateMap() => {
        'jobId': jobId,
        'jobTitle': jobTitle,
        'workerId': workerId,
        'workerName': workerName,
        'workerPhotoUrl': workerPhotoUrl,
        'clientId': clientId,
        'coverLetter': coverLetter,
        'proposedRate': proposedRate,
        'rateType': rateType,
        'estimatedDuration': estimatedDuration,
        'status': ProposalStatus.pending.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Re-sending a withdrawn proposal: new terms, back to pending.
  Map<String, dynamic> toResubmitMap() => {
        'coverLetter': coverLetter,
        'proposedRate': proposedRate,
        'rateType': rateType,
        'estimatedDuration': estimatedDuration,
        'workerName': workerName,
        'workerPhotoUrl': workerPhotoUrl,
        'status': ProposalStatus.pending.value,
        // Removed (not nulled) so the client can mark the new version viewed.
        'withdrawnAt': FieldValue.delete(),
        'viewedAt': FieldValue.delete(),
        'resubmittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

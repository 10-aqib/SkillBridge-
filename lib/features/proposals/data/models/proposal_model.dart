import 'package:cloud_firestore/cloud_firestore.dart';
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
    required super.workerRating,
    required super.coverLetter,
    required super.proposedRate,
    required super.rateType,
    required super.estimatedDuration,
    required super.status,
    required super.clientId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProposalModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProposalModel(
      id: doc.id,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'workerId': workerId,
      'workerName': workerName,
      'workerPhotoUrl': workerPhotoUrl,
      'workerRating': workerRating,
      'coverLetter': coverLetter,
      'proposedRate': proposedRate,
      'rateType': rateType,
      'estimatedDuration': estimatedDuration,
      'status': status.name,
      'clientId': clientId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

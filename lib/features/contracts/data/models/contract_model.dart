import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/enums/contract_status.dart';
import 'package:skill_bridge/core/enums/payment_method.dart';
import 'package:skill_bridge/core/enums/payment_status.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';

class ContractModel extends ContractEntity {
  const ContractModel({
    required super.id,
    required super.jobId,
    required super.jobTitle,
    required super.proposalId,
    required super.clientId,
    required super.clientName,
    super.clientPhotoUrl,
    required super.workerId,
    required super.workerName,
    super.workerPhotoUrl,
    required super.agreedRate,
    required super.rateType,
    required super.totalAmount,
    required super.commissionRate,
    required super.commissionAmount,
    required super.workerEarnings,
    required super.paymentStatus,
    required super.paymentMethod,
    super.paymentTransactionId,
    super.serviceAddress,
    super.serviceCity,
    super.serviceDate,
    super.serviceTimeSlot,
    super.clientPhone,
    required super.status,
    required super.startDate,
    super.endDate,
    super.completedAt,
    required super.clientReviewed,
    required super.workerReviewed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ContractModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContractModel(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      proposalId: data['proposalId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientPhotoUrl: data['clientPhotoUrl'],
      workerId: data['workerId'] ?? '',
      workerName: data['workerName'] ?? '',
      workerPhotoUrl: data['workerPhotoUrl'],
      agreedRate: (data['agreedRate'] ?? 0.0).toDouble(),
      rateType: data['rateType'] ?? 'fixed',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      commissionRate: (data['commissionRate'] ?? 1.0).toDouble(),
      commissionAmount: (data['commissionAmount'] ?? 0.0).toDouble(),
      workerEarnings: (data['workerEarnings'] ?? 0.0).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == data['paymentMethod'],
        orElse: () => PaymentMethod.jazzcash,
      ),
      paymentTransactionId: data['paymentTransactionId'],
      serviceAddress: data['serviceAddress'],
      serviceCity: data['serviceCity'],
      serviceDate: (data['serviceDate'] as Timestamp?)?.toDate(),
      serviceTimeSlot: data['serviceTimeSlot'],
      clientPhone: data['clientPhone'],
      status: ContractStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ContractStatus.active,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      clientReviewed: data['clientReviewed'] ?? false,
      workerReviewed: data['workerReviewed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'proposalId': proposalId,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhotoUrl': clientPhotoUrl,
      'workerId': workerId,
      'workerName': workerName,
      'workerPhotoUrl': workerPhotoUrl,
      'agreedRate': agreedRate,
      'rateType': rateType,
      'totalAmount': totalAmount,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'workerEarnings': workerEarnings,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod.name,
      'paymentTransactionId': paymentTransactionId,
      'serviceAddress': serviceAddress,
      'serviceCity': serviceCity,
      'serviceDate': serviceDate != null ? Timestamp.fromDate(serviceDate!) : null,
      'serviceTimeSlot': serviceTimeSlot,
      'clientPhone': clientPhone,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'clientReviewed': clientReviewed,
      'workerReviewed': workerReviewed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

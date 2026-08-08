import 'package:skill_bridge/core/enums/contract_status.dart';
import 'package:skill_bridge/core/enums/payment_method.dart';
import 'package:skill_bridge/core/enums/payment_status.dart';

class ContractEntity {
  final String id;
  final String jobId;
  final String jobTitle;
  final String proposalId;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String workerId;
  final String workerName;
  final String? workerPhotoUrl;
  final double agreedRate;
  final String rateType;
  final double totalAmount;
  final double commissionRate; // 10% (0.10)
  final double commissionAmount;
  final double workerEarnings;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? paymentTransactionId;
  
  // Scheduling & Location Fields
  final String? serviceAddress;
  final String? serviceCity;
  final DateTime? serviceDate;
  final String? serviceTimeSlot;
  final String? clientPhone;

  final ContractStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? completedAt;
  final bool clientReviewed;
  final bool workerReviewed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContractEntity({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.proposalId,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.workerId,
    required this.workerName,
    this.workerPhotoUrl,
    required this.agreedRate,
    required this.rateType,
    required this.totalAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.workerEarnings,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentTransactionId,
    this.serviceAddress,
    this.serviceCity,
    this.serviceDate,
    this.serviceTimeSlot,
    this.clientPhone,
    required this.status,
    required this.startDate,
    this.endDate,
    this.completedAt,
    required this.clientReviewed,
    required this.workerReviewed,
    required this.createdAt,
    required this.updatedAt,
  });
}

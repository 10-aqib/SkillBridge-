import 'package:latlong2/latlong.dart';
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

  // ── Phase 4A lifecycle (written only by the contract functions) ─────────
  /// The job's description at hiring time (the agreed work).
  final String jobDescription;
  final String estimatedDuration;

  /// Lower end when the agreed price is the client's budget range (direct
  /// requests); null for a single price.
  final double? priceMin;

  /// General area from the job (e.g. "Gulberg III"); the exact address is
  /// [serviceAddress], shared privately by the client after hiring.
  final String? serviceArea;
  final DateTime? addressSharedAt;

  /// The exact place pinned on the map by the client (Navigation phase 8):
  /// the destination for the worker's directions. Null until pinned.
  final LatLng? serviceLocation;
  final DateTime? serviceLocationSetAt;
  final DateTime? acceptedAt;
  final DateTime? respondedAt;
  final DateTime? workStartedAt;
  final DateTime? submittedAt;
  final String? submissionNote;
  final List<String> submissionAttachments;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancelledByRole;
  final String? cancelReason;
  final String? cancelNote;

  // ── Phase 4B coordination (written only by the contract functions) ──────
  /// Submissions so far; null on Phase 4A contracts (see [submissions]).
  final int? submissionCount;

  /// Times the client sent the work back for changes (at most [maxRevisions]).
  final int revisionCount;
  final DateTime? revisionRequestedAt;
  final String? revisionNote;

  /// Progress updates the worker has posted, and the latest one's time.
  final int updateCount;
  final DateTime? lastUpdateAt;

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
    this.jobDescription = '',
    this.estimatedDuration = '',
    this.priceMin,
    this.serviceArea,
    this.addressSharedAt,
    this.serviceLocation,
    this.serviceLocationSetAt,
    this.acceptedAt,
    this.respondedAt,
    this.workStartedAt,
    this.submittedAt,
    this.submissionNote,
    this.submissionAttachments = const [],
    this.cancelledAt,
    this.cancelledBy,
    this.cancelledByRole,
    this.cancelReason,
    this.cancelNote,
    this.submissionCount,
    this.revisionCount = 0,
    this.revisionRequestedAt,
    this.revisionNote,
    this.updateCount = 0,
    this.lastUpdateAt,
  });

  /// Revision rounds a client may ask for (same as the server).
  static const int maxRevisions = 3;

  /// Submissions so far. Phase 4A contracts have no counter: a set
  /// [submittedAt] means one submission.
  int get submissions => submissionCount ?? (submittedAt != null ? 1 : 0);

  /// Where the work stands, by the same rule as the server (stageOf in
  /// functions/src/contracts.ts): submitted while there are more
  /// submissions than revision requests; sent back means in progress again.
  ContractStage get stage => switch (status) {
        ContractStatus.pending => ContractStage.requested,
        ContractStatus.active when submissions > revisionCount => ContractStage.submitted,
        ContractStatus.active when workStartedAt != null => ContractStage.inProgress,
        ContractStatus.active => ContractStage.notStarted,
        ContractStatus.completed => ContractStage.completed,
        ContractStatus.cancelled || ContractStatus.disputed => ContractStage.cancelled,
        ContractStatus.rejected => ContractStage.declined,
      };

  bool get isDirectBooking => proposalId == 'direct_hire';

  /// Accepted from a direct request (a job sent to one worker).
  bool get isDirectRequest => proposalId == 'direct_request';

  /// Either party may cancel until the work is submitted.
  bool get canCancel => stage == ContractStage.requested || stage == ContractStage.notStarted || stage == ContractStage.inProgress;

  /// The client sent the work back and the worker hasn't resubmitted yet.
  bool get awaitingResubmission => stage == ContractStage.inProgress && revisionCount > 0 && submissions == revisionCount;

  int get revisionsLeft => (maxRevisions - revisionCount).clamp(0, maxRevisions);
}

enum ContractStage { requested, notStarted, inProgress, submitted, completed, cancelled, declined }

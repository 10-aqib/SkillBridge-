class ReviewEntity {
  final String id;
  final String contractId;
  final String jobId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final String revieweeId;
  final String revieweeName;
  final double rating;
  final String comment;
  final String reviewType; // 'client_to_worker' | 'worker_to_client'
  final DateTime createdAt;
  
  // Module 2 Additions
  final List<String>? photos;
  final String? workerReply;
  final DateTime? workerReplyAt;
  final int helpfulVotes;
  final List<String> upvoters;
  final bool isVerifiedCustomer;

  const ReviewEntity({
    required this.id,
    required this.contractId,
    required this.jobId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.revieweeId,
    required this.revieweeName,
    required this.rating,
    required this.comment,
    this.reviewType = 'client_to_worker',
    required this.createdAt,
    this.photos,
    this.workerReply,
    this.workerReplyAt,
    this.helpfulVotes = 0,
    this.upvoters = const [],
    this.isVerifiedCustomer = false,
  });
}

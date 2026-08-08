import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/reviews/domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.contractId,
    required super.jobId,
    required super.reviewerId,
    required super.reviewerName,
    super.reviewerPhotoUrl,
    required super.revieweeId,
    required super.revieweeName,
    required super.rating,
    required super.comment,
    super.reviewType = 'client_to_worker',
    required super.createdAt,
    super.photos,
    super.workerReply,
    super.workerReplyAt,
    super.helpfulVotes = 0,
    super.upvoters = const [],
    super.isVerifiedCustomer = false,
  });

  factory ReviewModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      contractId: data['contractId'] ?? '',
      jobId: data['jobId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      reviewerPhotoUrl: data['reviewerPhotoUrl'],
      revieweeId: data['revieweeId'] ?? '',
      revieweeName: data['revieweeName'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      reviewType: data['reviewType'] ?? 'client_to_worker',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photos: (data['photos'] as List?)?.map((e) => e as String).toList(),
      workerReply: data['workerReply'],
      workerReplyAt: (data['workerReplyAt'] as Timestamp?)?.toDate(),
      helpfulVotes: data['helpfulVotes'] ?? 0,
      upvoters: (data['upvoters'] as List?)?.map((e) => e as String).toList() ?? [],
      isVerifiedCustomer: data['isVerifiedCustomer'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'jobId': jobId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'revieweeId': revieweeId,
      'revieweeName': revieweeName,
      'rating': rating,
      'comment': comment,
      'reviewType': reviewType,
      'createdAt': FieldValue.serverTimestamp(),
      if (photos != null) 'photos': photos,
      if (workerReply != null) 'workerReply': workerReply,
      if (workerReplyAt != null) 'workerReplyAt': workerReplyAt,
      'helpfulVotes': helpfulVotes,
      'upvoters': upvoters,
      'isVerifiedCustomer': isVerifiedCustomer,
    };
  }
}

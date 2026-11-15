import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/reviews/data/models/review_model.dart';

/// The rating ledger after one more review of [rating] stars: count, sum and
/// the average to one decimal (exactly as the rules compute it).
Map<String, num> nextRatingLedger(Map<String, dynamic> ledger, num rating) {
  final count = ((ledger['count'] as num?) ?? 0).toInt() + 1;
  final sum = ((ledger['sum'] as num?) ?? 0) + rating;
  return {'count': count, 'sum': sum, 'average': (sum / count * 10).round() / 10.0};
}

abstract class ReviewRemoteDataSource {
  Future<void> submitReview({
    required ReviewModel review,
    required bool isClientReview,
  });
  Stream<List<ReviewModel>> getReviewsForUser(String userId);
  Future<void> updateHelpfulVote(String reviewId, String userId, bool isAdding);
  Future<void> addWorkerReply(String reviewId, String reply);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final FirebaseFirestore _firestore;

  ReviewRemoteDataSourceImpl(this._firestore);

  @override
  Future<void> submitReview({
    required ReviewModel review,
    required bool isClientReview,
  }) async {
    try {
      final reviewId = '${review.contractId}_${review.reviewerId}';
      final reviewRef = _firestore.collection(FirestorePaths.reviews).doc(reviewId);
      final contractRef = _firestore.collection(FirestorePaths.contracts).doc(review.contractId);
      final ledgerRef = _firestore.collection(FirestorePaths.ratings).doc(review.revieweeId);
      // Free plan (Phase S5; was aggregateReviewRating): the review, the
      // contract's review flag and the reviewee's rating ledger in one
      // transaction. The rules check the ledger moves by exactly this review.
      await _firestore.runTransaction((tx) async {
        final ledger = (await tx.get(ledgerRef)).data() ?? const <String, dynamic>{};
        final next = nextRatingLedger(ledger, review.rating);
        tx.set(reviewRef, review.toMap());
        tx.update(contractRef, {isClientReview ? 'clientReviewed' : 'workerReviewed': true});
        tx.set(ledgerRef, {...next, 'lastReviewId': reviewId, 'updatedAt': FieldValue.serverTimestamp()});
        final comment = review.comment.length > 200 ? '${review.comment.substring(0, 197)}…' : review.comment;
        tx.set(_firestore.collection(FirestorePaths.notifications).doc(), {
          'userId': review.revieweeId,
          'title': 'New Review Received',
          'body': '${review.reviewerName} rated you ${review.rating} stars: "$comment"',
          'type': 'review_received',
          'payload': {'contractId': review.contractId},
          'referenceId': review.contractId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      });
    } catch (e) {
      throw ServerException('Failed to submit review: $e');
    }
  }

  @override
  Stream<List<ReviewModel>> getReviewsForUser(String userId) {
    return _firestore
        .collection(FirestorePaths.reviews)
        .where('revieweeId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => ReviewModel.fromSnapshot(d))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Future<void> updateHelpfulVote(
    String reviewId,
    String userId,
    bool isAdding,
  ) async {
    try {
      final reviewRef = _firestore
          .collection(FirestorePaths.reviews)
          .doc(reviewId);
      if (isAdding) {
        await reviewRef.update({
          'helpfulVotes': FieldValue.increment(1),
          'upvoters': FieldValue.arrayUnion([userId]),
        });
      } else {
        await reviewRef.update({
          'helpfulVotes': FieldValue.increment(-1),
          'upvoters': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      throw ServerException('Failed to update helpful vote: $e');
    }
  }

  @override
  Future<void> addWorkerReply(String reviewId, String reply) async {
    try {
      final reviewRef = _firestore
          .collection(FirestorePaths.reviews)
          .doc(reviewId);
      await reviewRef.update({
        'workerReply': reply,
        'workerReplyAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to add worker reply: $e');
    }
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>((ref) {
  return ReviewRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

final userReviewsStreamProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
      return ref
          .watch(reviewRemoteDataSourceProvider)
          .getReviewsForUser(userId);
    });

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/reviews/data/models/review_model.dart';

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
      final batch = _firestore.batch();
      
      // Save review document
      final reviewRef = _firestore.collection(FirestorePaths.reviews).doc();
      batch.set(reviewRef, review.toMap());

      // Update corresponding review flag in contract
      final contractRef = _firestore
          .collection(FirestorePaths.contracts)
          .doc(review.contractId);
          
      if (isClientReview) {
        batch.update(contractRef, {'clientReviewed': true});
      } else {
        batch.update(contractRef, {'workerReviewed': true});
      }

      // Update reviewee's average rating correctly (1.0 to 5.0 scale)
      final userDoc = await _firestore
          .collection(FirestorePaths.users)
          .doc(review.revieweeId)
          .get();
      final userData = userDoc.data() ?? {};
      final double currentRating = (userData['rating'] ?? 5.0).toDouble();
      final int currentReviews = (userData['totalReviews'] ?? 0) as int;
      final int newTotalReviews = currentReviews + 1;
      final double newRating =
          ((currentRating * currentReviews) + review.rating) / newTotalReviews;

      final userRef =
          _firestore.collection(FirestorePaths.users).doc(review.revieweeId);
      batch.update(userRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'totalReviews': newTotalReviews,
      });

      // Create notification for reviewee
      final notifRef =
          _firestore.collection(FirestorePaths.notifications).doc();
      batch.set(notifRef, {
        'userId': review.revieweeId,
        'title': 'New Review Received • نیا جائزہ موصول ہوا',
        'body':
            '${review.reviewerName} rated you ${review.rating} stars: "${review.comment}"',
        'type': 'review_received',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await batch.commit();
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
      final list = snap.docs.map((d) => ReviewModel.fromSnapshot(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> updateHelpfulVote(String reviewId, String userId, bool isAdding) async {
    try {
      final reviewRef = _firestore.collection(FirestorePaths.reviews).doc(reviewId);
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
      final reviewRef = _firestore.collection(FirestorePaths.reviews).doc(reviewId);
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

final userReviewsStreamProvider = StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
  return ref.watch(reviewRemoteDataSourceProvider).getReviewsForUser(userId);
});

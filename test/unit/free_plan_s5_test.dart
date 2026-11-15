import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/services/public_profile_sync.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';

void main() {
  group('chat preview (stored with each message, at most 120 characters)', () {
    test('text is trimmed and spaces collapsed', () {
      expect(chatPreviewOf('  Hello,\n  are you   free?  ', isImage: false), 'Hello, are you free?');
    });
    test('photos read "Photo", with any caption', () {
      expect(chatPreviewOf('', isImage: true), 'Photo');
      expect(chatPreviewOf('the socket', isImage: true), 'Photo: the socket');
    });
    test('long text is cut to 120 characters', () {
      expect(chatPreviewOf('x' * 300, isImage: false).length, 120);
    });
  });

  group('rating ledger (must equal the rules\' arithmetic)', () {
    test('first review', () {
      expect(nextRatingLedger({}, 5), {'count': 1, 'sum': 5, 'average': 5.0});
    });
    test('average to one decimal', () {
      expect(nextRatingLedger({'count': 2, 'sum': 9, 'average': 4.5}, 4), {'count': 3, 'sum': 13, 'average': 4.3});
      expect(nextRatingLedger({'count': 1, 'sum': 5.0, 'average': 5.0}, 4.0)['average'], 4.5);
    });
  });

  group('copying the ledger onto the account', () {
    test('nothing to copy without a ledger, or when it already matches', () {
      expect(ratingsCopyFor({'rating': 5, 'totalReviews': 0}, null), isNull);
      expect(ratingsCopyFor({'rating': 4.5, 'totalReviews': 2}, {'count': 2, 'sum': 9, 'average': 4.5}), isNull);
    });
    test('copies account and worker numbers that differ', () {
      final update = ratingsCopyFor({
        'rating': 5, 'totalReviews': 0,
        'workerProfile': {'averageRating': 0, 'totalReviews': 0, 'totalJobsCompleted': 3},
      }, {'count': 2, 'sum': 9, 'average': 4.5});
      expect(update, {
        'rating': 4.5, 'totalReviews': 2, 'workerProfile.averageRating': 4.5, 'workerProfile.totalReviews': 2,
      });
    });
    test('clients have no worker numbers to copy', () {
      expect(ratingsCopyFor({'rating': 5, 'totalReviews': 0}, {'count': 1, 'sum': 4, 'average': 4.0}),
          {'rating': 4.0, 'totalReviews': 1});
    });
  });
}

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:skill_bridge/core/utils/logger.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      Logger.i('Analytics: setUserId -> $userId');
    } catch (e, st) {
      Logger.e('Analytics setUserId error', e, st);
    }
  }

  Future<void> setUserRole(String role) async {
    try {
      await _analytics.setUserProperty(name: 'user_role', value: role);
      Logger.i('Analytics: setUserRole -> $role');
    } catch (e, st) {
      Logger.e('Analytics setUserRole error', e, st);
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      Logger.i('Analytics: logLogin -> $method');
    } catch (e, st) {
      Logger.e('Analytics logLogin error', e, st);
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      Logger.i('Analytics: logSignUp -> $method');
    } catch (e, st) {
      Logger.e('Analytics logSignUp error', e, st);
    }
  }

  Future<void> logJobPosted({required String jobId, String? category}) async {
    try {
      await _analytics.logEvent(
        name: 'job_posted',
        parameters: {'job_id': jobId, 'category': ?category},
      );
      Logger.i('Analytics: logJobPosted -> $jobId');
    } catch (e, st) {
      Logger.e('Analytics logJobPosted error', e, st);
    }
  }

  Future<void> logProposalSubmitted({
    required String proposalId,
    required String jobId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'proposal_submitted',
        parameters: {'proposal_id': proposalId, 'job_id': jobId},
      );
      Logger.i('Analytics: logProposalSubmitted -> $proposalId');
    } catch (e, st) {
      Logger.e('Analytics logProposalSubmitted error', e, st);
    }
  }

  Future<void> logContractCreated({required String contractId}) async {
    try {
      await _analytics.logEvent(
        name: 'contract_created',
        parameters: {'contract_id': contractId},
      );
      Logger.i('Analytics: logContractCreated -> $contractId');
    } catch (e, st) {
      Logger.e('Analytics logContractCreated error', e, st);
    }
  }

  Future<void> logReviewSubmitted({
    required String reviewId,
    required int rating,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'review_submitted',
        parameters: {'review_id': reviewId, 'rating': rating},
      );
      Logger.i('Analytics: logReviewSubmitted -> $reviewId');
    } catch (e, st) {
      Logger.e('Analytics logReviewSubmitted error', e, st);
    }
  }

  Future<void> logSearch(String searchTerm) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      Logger.i('Analytics: logSearch -> $searchTerm');
    } catch (e, st) {
      Logger.e('Analytics logSearch error', e, st);
    }
  }
}

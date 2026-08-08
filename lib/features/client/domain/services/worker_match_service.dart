import 'dart:math';
import 'package:skill_bridge/features/client/domain/entities/nearby_worker_entity.dart';

/// SkillBridge Match Service (FYP Proposal B3 / Section 2.1.4)
/// Computes a composite match score (0.0 to 100.0) based on:
/// - 40% Skill/Category match
/// - 25% Rating compatibility
/// - 20% Distance / Location proximity
/// - 15% Rate compatibility
class WorkerMatchService {
  static double computeMatchScore({
    required NearbyWorkerEntity worker,
    required String targetCategory,
    required double maxHourlyRate,
  }) {
    // 1. Skill Match (40%)
    double skillScore = 0.5;
    if (targetCategory == 'All' ||
        worker.category.toLowerCase() == targetCategory.toLowerCase()) {
      skillScore = 1.0;
    }

    // 2. Rating (25%)
    double ratingScore = (worker.rating.clamp(0.0, 5.0)) / 5.0;

    // 3. Distance / Proximity (20%) - 0km is 1.0, 50km+ is 0.0
    double distanceScore = max(0.0, 1.0 - (worker.distanceKm / 50.0));

    // 4. Rate Compatibility (15%)
    double rateScore = 1.0;
    if (maxHourlyRate > 0) {
      if (worker.hourlyRate <= maxHourlyRate) {
        rateScore = 1.0;
      } else {
        rateScore = max(0.0, 1.0 - ((worker.hourlyRate - maxHourlyRate) / maxHourlyRate));
      }
    }

    final totalScore = (0.40 * skillScore) +
        (0.25 * ratingScore) +
        (0.20 * distanceScore) +
        (0.15 * rateScore);

    return (totalScore * 100.0).clamp(0.0, 100.0);
  }

  /// Returns workers sorted by match score descending, with updated matchScore field
  static List<NearbyWorkerEntity> sortWorkersByMatch({
    required List<NearbyWorkerEntity> workers,
    required String targetCategory,
    required double maxHourlyRate,
  }) {
    final scoredWorkers = workers.map((worker) {
      final score = computeMatchScore(
        worker: worker,
        targetCategory: targetCategory,
        maxHourlyRate: maxHourlyRate,
      );
      return worker.copyWith(matchScore: score);
    }).toList();

    scoredWorkers.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return scoredWorkers;
  }
}

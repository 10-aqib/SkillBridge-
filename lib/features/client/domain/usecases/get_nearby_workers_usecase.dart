import 'package:skill_bridge/features/client/domain/entities/nearby_worker_entity.dart';
import 'package:skill_bridge/features/client/domain/repositories/worker_repository.dart';

class GetNearbyWorkersUseCase {
  final WorkerRepository _repository;

  GetNearbyWorkersUseCase(this._repository);

  Stream<List<NearbyWorkerEntity>> call(GeoPointLocation userLocation, {double maxDistanceKm = 5.0}) {
    return _repository.getNearbyWorkersStream(userLocation.latitude, userLocation.longitude, maxDistanceKm).map((users) {
      final workers = <NearbyWorkerEntity>[];

      for (var user in users) {
        if (!user.isWorker) continue;
        
        final geoMap = user.location;
        if (geoMap == null) continue; // Skip workers without location

        final workerLoc = GeoPointLocation(
          latitude: geoMap.latitude,
          longitude: geoMap.longitude,
        );
        
        final distKm = userLocation.distanceTo(workerLoc);
        final profile = user.workerProfile;
        // Same rating source as the client home cards: the worker profile's
        // ledger copy when it has reviews, else the account's.
        final profileHasReviews = (profile?.totalReviews ?? 0) > 0;
        final reviewCount =
            profileHasReviews ? profile!.totalReviews : user.totalReviews;

        workers.add(
          NearbyWorkerEntity(
            workerId: user.uid,
            name: user.displayName,
            category: profile?.categoryName ?? 'Worker',
            hourlyRate: profile?.hourlyRate ?? 0.0,
            rating: reviewCount == 0
                ? 0.0
                : (profileHasReviews ? profile!.averageRating : user.rating),
            profilePicture: user.photoUrl,
            location: workerLoc,
            distanceKm: distKm,
            // 'available' | 'busy' | 'offline'; missing means a new profile,
            // which starts as available.
            isAvailable:
                (profile?.availability ?? 'available').toLowerCase() ==
                    'available',
            isVerified: profile?.isVerified ?? false,
            reviewCount: reviewCount,
          ),
        );
      }

      // Sort by distance
      workers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return workers;
    });
  }
}

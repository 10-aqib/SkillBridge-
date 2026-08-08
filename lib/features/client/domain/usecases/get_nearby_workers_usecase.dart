import 'package:skill_bridge/features/client/domain/entities/nearby_worker_entity.dart';
import 'package:skill_bridge/features/client/domain/repositories/worker_repository.dart';

class GetNearbyWorkersUseCase {
  final WorkerRepository _repository;

  GetNearbyWorkersUseCase(this._repository);

  Stream<List<NearbyWorkerEntity>> call(GeoPointLocation userLocation, {double maxDistanceKm = 5.0}) {
    return _repository.getWorkersStream().map((users) {
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

        if (distKm <= maxDistanceKm) {
          workers.add(
            NearbyWorkerEntity(
              workerId: user.uid,
              name: user.displayName,
              category: user.workerProfile?.categoryName ?? 'Worker',
              hourlyRate: user.workerProfile?.hourlyRate ?? 0.0,
              rating: user.rating,
              profilePicture: user.photoUrl,
              location: workerLoc,
              distanceKm: distKm,
            ),
          );
        }
      }

      // Sort by distance
      workers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return workers;
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/core/utils/geohash_util.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';

abstract class WorkerRemoteDataSource {
  Stream<List<UserModel>> getWorkersStream();
  Stream<List<UserModel>> getNearbyWorkersStream(double latitude, double longitude, double radiusKm);
}

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  final FirebaseFirestore _firestore;

  WorkerRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<UserModel>> getWorkersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<UserModel>> getNearbyWorkersStream(double latitude, double longitude, double radiusKm) {
    // 1. Calculate geohash bounds for the query
    final range = GeohashUtil.getGeohashRange(latitude, longitude, radiusKm);
    final lower = range[0];
    final upper = range[1];

    // 2. Query Firestore using the geohash range
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .where('geohash', isGreaterThanOrEqualTo: lower)
        .where('geohash', isLessThanOrEqualTo: upper)
        .snapshots()
        .map((snapshot) {
      final workers = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // 3. Post-filter using exact Haversine distance since geohash bounds are rectangular/approximate
      return workers.where((worker) {
        if (worker.location == null) return false;
        
        final distance = GeoLocationUtil.calculateDistanceKm(
          latitude,
          longitude,
          worker.location!.latitude,
          worker.location!.longitude,
        );
        
        return distance <= radiusKm;
      }).toList();
    });
  }
}

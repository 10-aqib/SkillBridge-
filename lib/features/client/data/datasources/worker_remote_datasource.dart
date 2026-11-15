import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/services/offline_cache_service.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/core/utils/geohash_util.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';

abstract class WorkerRemoteDataSource {
  Stream<List<UserModel>> getWorkersStream();
  Stream<List<UserModel>> getNearbyWorkersStream(
    double latitude,
    double longitude,
    double radiusKm,
  );
}

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  final FirebaseFirestore _firestore;

  WorkerRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Discovery reads public profiles only: no phone, email or addresses, and
  // worker locations coarsened to about 1 km (see core/services/public_profile_sync.dart).
  @override
  Stream<List<UserModel>> getWorkersStream() {
    final query = _firestore
        .collection(FirestorePaths.publicProfiles)
        .where('role', isEqualTo: 'worker');
    return _watchCachedWorkers(query, 'workers:all');
  }

  @override
  Stream<List<UserModel>> getNearbyWorkersStream(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    // 1. Calculate geohash bounds for the query
    final range = GeohashUtil.getGeohashRange(latitude, longitude, radiusKm);
    final lower = range[0];
    final upper = range[1];

    // 2. Query Firestore using the geohash range
    final query = _firestore
        .collection(FirestorePaths.publicProfiles)
        .where('role', isEqualTo: 'worker')
        .where('geohash', isGreaterThanOrEqualTo: lower)
        .where('geohash', isLessThanOrEqualTo: upper);
    return _watchCachedWorkers(query, 'workers:near:$lower:$upper').map((
      workers,
    ) {
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

  Stream<List<UserModel>> _watchCachedWorkers(
    Query<Map<String, dynamic>> query,
    String cacheKey,
  ) async* {
    final cached = OfflineCacheService.readDecoded(cacheKey);
    if (cached is List) {
      yield cached
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .map((record) {
            final id = record.remove('__docId') as String? ?? '';
            return UserModel.fromMap(id, record);
          })
          .toList();
    }

    try {
      final snapshots = StreamIterator(query.snapshots());
      try {
        final hasFirstSnapshot = await snapshots.moveNext().timeout(
          const Duration(seconds: 15),
        );
        if (!hasFirstSnapshot) return;

        do {
          final snapshot = snapshots.current;
          final workers = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
          final publicRecords = snapshot.docs.map((doc) {
            final user = UserModel.fromFirestore(doc);
            final source = doc.data();
            final workerProfile = source['workerProfile'];
            const publicUserFields = [
              'displayName',
              'photoUrl',
              'role',
              'isActive',
              'city',
              'location',
              'isLocationSharing',
              'locationUpdatedAt',
              'geohash',
              'locationAccuracy',
              'rating',
              'totalReviews',
            ];
            const publicWorkerFields = [
              'headline',
              'bio',
              'categoryId',
              'categoryName',
              'skills',
              'experience',
              'hourlyRate',
              'dailyRate',
              'availability',
              'isVerified',
              'city',
              'location',
              'serviceRadius',
              'totalJobsCompleted',
              'averageRating',
              'totalReviews',
              'geohash',
              'locationAccuracy',
              'coverImage',
              'languages',
              'responseTime',
              'beforeAfterImages',
            ];
            return {
              for (final field in publicUserFields)
                if (source.containsKey(field)) field: source[field],
              'uid': user.uid,
              'workerProfile': workerProfile is Map
                  ? {
                      for (final field in publicWorkerFields)
                        if (workerProfile.containsKey(field))
                          field: workerProfile[field],
                    }
                  : <String, dynamic>{},
              '__docId': doc.id,
            };
          }).toList();
          await OfflineCacheService.save(cacheKey, publicRecords);
          yield workers;
        } while (await snapshots.moveNext());
      } finally {
        await snapshots.cancel();
      }
    } catch (_) {
      if (cached == null) rethrow;
    }
  }
}

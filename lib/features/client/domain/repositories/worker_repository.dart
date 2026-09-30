import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

abstract class WorkerRepository {
  Stream<List<UserEntity>> getWorkersStream();
  Stream<List<UserEntity>> getNearbyWorkersStream(double latitude, double longitude, double radiusKm);
}

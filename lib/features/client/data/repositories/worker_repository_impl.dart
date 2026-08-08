import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/client/data/datasources/worker_remote_datasource.dart';
import 'package:skill_bridge/features/client/domain/repositories/worker_repository.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  final WorkerRemoteDataSource _remoteDataSource;

  WorkerRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<UserEntity>> getWorkersStream() {
    return _remoteDataSource.getWorkersStream();
  }
}

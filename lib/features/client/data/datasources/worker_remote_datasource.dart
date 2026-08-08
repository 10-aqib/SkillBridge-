import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';

abstract class WorkerRemoteDataSource {
  Stream<List<UserModel>> getWorkersStream();
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
}

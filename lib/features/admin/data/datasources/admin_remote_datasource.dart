import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';

class AdminStatsModel {
  final int totalUsers;
  final int activeWorkers;
  final int activeClients;
  final int totalJobs;
  final int activeContracts;
  final double totalRevenue;
  final double totalCommission;

  const AdminStatsModel({
    required this.totalUsers,
    required this.activeWorkers,
    required this.activeClients,
    required this.totalJobs,
    required this.activeContracts,
    required this.totalRevenue,
    required this.totalCommission,
  });
}

class AdminRemoteDataSource {
  final FirebaseFirestore _firestore;

  AdminRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<AdminStatsModel> getStatsStream() {
    return _firestore.collection('users').snapshots().asyncMap((usersSnap) async {
      final totalUsers = usersSnap.docs.length;
      final activeWorkers = usersSnap.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'worker';
      }).length;
      final activeClients = usersSnap.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'client';
      }).length;

      final jobsCountQuery = await _firestore.collection('jobs').count().get();
      final totalJobs = jobsCountQuery.count ?? 0;

      final contractsRef = _firestore.collection('contracts');
      final activeContractsQuery = await contractsRef.where('status', whereIn: ['active', 'in_progress']).count().get();
      final activeContracts = activeContractsQuery.count ?? 0;

      final revenueAggregate = await contractsRef.aggregate(sum('totalAmount')).get();
      final commissionAggregate = await contractsRef.aggregate(sum('commissionAmount')).get();
      
      final totalRevenue = revenueAggregate.getSum('totalAmount') ?? 0.0;
      final totalCommission = commissionAggregate.getSum('commissionAmount') ?? 0.0;

      return AdminStatsModel(
        totalUsers: totalUsers,
        activeWorkers: activeWorkers,
        activeClients: activeClients,
        totalJobs: totalJobs,
        activeContracts: activeContracts,
        totalRevenue: totalRevenue.toDouble(),
        totalCommission: totalCommission.toDouble(),
      );
    });
  }

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'status': isActive ? 'active' : 'suspended',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleWorkerVerification(String userId, bool isVerified) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': isVerified,
    });
  }

  Stream<List<JobModel>> getJobsStream() {
    return _firestore.collection('jobs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => JobModel.fromSnapshot(doc)).toList();
    });
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).delete();
  }
}


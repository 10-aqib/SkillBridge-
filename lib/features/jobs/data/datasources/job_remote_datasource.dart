import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';

abstract class JobRemoteDataSource {
  Future<String> createJob(JobModel job);
  Future<void> updateJob(String jobId, Map<String, dynamic> data);
  Future<void> deleteJob(String jobId);
  Future<JobModel?> getJobById(String jobId);
  Future<void> startJob(String jobId);
  Future<void> completeJob(String jobId);
  Stream<List<JobModel>> getOpenJobs();
  Stream<List<JobModel>> getJobsByClient(String clientId);
  Stream<List<JobModel>> getJobsByCategory(String categoryId);
  Future<void> payJob(String jobId);
}

class JobRemoteDataSourceImpl implements JobRemoteDataSource {
  final FirebaseFirestore _firestore;

  JobRemoteDataSourceImpl(this._firestore);

  @override
  Future<String> createJob(JobModel job) async {
    try {
      final docRef = await _firestore
          .collection(FirestorePaths.jobs)
          .add(job.toMap());
      return docRef.id;
    } catch (e) {
      throw ServerException('Failed to create job post: $e');
    }
  }

  @override
  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirestorePaths.jobs)
          .doc(jobId)
          .update(data);
    } catch (e) {
      throw ServerException('Failed to update job: $e');
    }
  }

  @override
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection(FirestorePaths.jobs).doc(jobId).delete();
    } catch (e) {
      throw ServerException('Failed to delete job: $e');
    }
  }

  @override
  Future<void> startJob(String jobId) async {
    try {
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc(jobId);
      final jobDoc = await jobRef.get();
      final data = jobDoc.data() ?? {};
      final clientId = data['clientId'] as String?;
      final title = data['title'] as String? ?? 'Job';

      final batch = _firestore.batch();
      batch.update(jobRef, {
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (clientId != null && clientId.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': clientId,
          'title': 'Job Started 🚀',
          'body': 'Work has started on "$title".',
          'payload': {'jobId': jobId},
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to start job: $e');
    }
  }

  @override
  Future<void> completeJob(String jobId) async {
    try {
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc(jobId);
      final jobDoc = await jobRef.get();
      final data = jobDoc.data() ?? {};
      final clientId = data['clientId'] as String?;
      final workerId = data['selectedWorkerId'] as String?;
      final title = data['title'] as String? ?? 'Job';

      final batch = _firestore.batch();
      batch.update(jobRef, {
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final userId in [clientId, workerId]) {
        if (userId != null && userId.isNotEmpty) {
          final notifRef = _firestore.collection('notifications').doc();
          batch.set(notifRef, {
            'userId': userId,
            'title': 'Job Completed! ✅',
            'body': ' "$title" has been completed. Don\'t forget to leave a review!',
            'payload': {'jobId': jobId},
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to complete job: $e');
    }
  }

  @override
  Future<void> payJob(String jobId) async {
    try {
      await _firestore.collection(FirestorePaths.jobs).doc(jobId).update({
        'isPaid': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to process payment for job: $e');
    }
  }

  @override
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final doc =
          await _firestore.collection(FirestorePaths.jobs).doc(jobId).get();
      if (!doc.exists) return null;
      return JobModel.fromSnapshot(doc);
    } catch (e) {
      throw ServerException('Failed to fetch job details: $e');
    }
  }

  @override
  Stream<List<JobModel>> getOpenJobs() {
    return _firestore
        .collection(FirestorePaths.jobs)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => JobModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Stream<List<JobModel>> getJobsByClient(String clientId) {
    return _firestore
        .collection(FirestorePaths.jobs)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => JobModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Stream<List<JobModel>> getJobsByCategory(String categoryId) {
    return _firestore
        .collection(FirestorePaths.jobs)
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => JobModel.fromSnapshot(doc)).toList();
    });
  }
}

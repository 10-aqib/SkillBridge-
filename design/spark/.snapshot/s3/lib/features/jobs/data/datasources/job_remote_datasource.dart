import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/services/offline_cache_service.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';
import 'package:skill_bridge/core/services/offline_outbox_service.dart';

abstract class JobRemoteDataSource {
  Future<JobCreateResult> createJob(JobModel job);
  Future<void> updateJob(String jobId, Map<String, dynamic> data);
  Future<void> deleteJob(String jobId);
  Future<JobModel?> getJobById(String jobId);
  Future<void> startJob(String jobId);
  Future<void> completeJob(String jobId);
  Stream<List<JobModel>> getOpenJobs();
  Stream<List<JobModel>> getJobsByClient(String clientId);
  Stream<List<JobModel>> getJobsByCategory(String categoryId);
  Future<void> payJob(String jobId);
  Future<void> acceptJob(String jobId, String workerId, String workerName);
  Future<void> rejectJob(String jobId);
  Stream<List<JobModel>> getDirectRequests(String workerId);

  /// Saves an edited open job (content fields only, see JobModel.toEditMap).
  Future<void> editJob(JobModel job);

  /// Close (cancelled) or reopen (open) a job the client owns.
  Future<void> setJobStatus(String jobId, String status);

  /// Live job document (null once missing or no longer readable).
  Stream<JobModel?> watchJob(String jobId);

}

class JobCreateResult {
  final String id;
  final bool queuedOffline;

  const JobCreateResult({required this.id, required this.queuedOffline});
}

class JobRemoteDataSourceImpl implements JobRemoteDataSource {
  final FirebaseFirestore _firestore;

  JobRemoteDataSourceImpl(this._firestore);

  @override
  Future<JobCreateResult> createJob(JobModel job) async {
    try {
      final batch = _firestore.batch();
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc();
      final writes = <Map<String, dynamic>>[];
      final jobData = job.toCreateMap();

      batch.set(jobRef, jobData);
      writes.add({
        'operation': 'set',
        'documentPath': jobRef.path,
        'data': jobData,
        'merge': false,
      });

      if (job.selectedWorkerId != null && job.selectedWorkerId!.isNotEmpty) {
        final notificationRef = _firestore
            .collection(FirestorePaths.notifications)
            .doc();
        final notificationData = {
          'userId': job.selectedWorkerId,
          'title': 'New Direct Request',
          'body':
              '${job.clientName.trim().isEmpty ? 'A client' : job.clientName} requested you for "${job.title}".',
          'payload': {'jobId': jobRef.id},
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        };
        batch.set(notificationRef, notificationData);
        writes.add({
          'operation': 'set',
          'documentPath': notificationRef.path,
          'data': notificationData,
          'merge': false,
        });
      }

      try {
        await batch.commit().timeout(const Duration(seconds: 15));
        return JobCreateResult(id: jobRef.id, queuedOffline: false);
      } on FirebaseException catch (error) {
        const networkCodes = {
          'unavailable',
          'deadline-exceeded',
          'network-request-failed',
        };
        if (!networkCodes.contains(error.code)) rethrow;

        await OfflineOutboxService.enqueue(
          type: 'FIRESTORE_BATCH',
          payload: {'writes': writes},
          idempotencyKey: 'create-job:${jobRef.id}',
        );
        return JobCreateResult(id: jobRef.id, queuedOffline: true);
      } on TimeoutException {
        await OfflineOutboxService.enqueue(
          type: 'FIRESTORE_BATCH',
          payload: {'writes': writes},
          idempotencyKey: 'create-job:${jobRef.id}',
        );
        return JobCreateResult(id: jobRef.id, queuedOffline: true);
      }
    } catch (e) {
      throw ServerException('Failed to create job post: $e');
    }
  }

  @override
  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(FirestorePaths.jobs).doc(jobId).update(data);
    } catch (e) {
      throw ServerException('Failed to update job: $e');
    }
  }

  @override
  Future<void> editJob(JobModel job) async {
    try {
      await _firestore.collection(FirestorePaths.jobs).doc(job.id).update(job.toEditMap());
    } catch (e) {
      throw ServerException('Failed to update job: $e');
    }
  }

  @override
  Future<void> setJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection(FirestorePaths.jobs).doc(jobId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to update job: $e');
    }
  }

  @override
  Stream<JobModel?> watchJob(String jobId) {
    return _firestore
        .collection(FirestorePaths.jobs)
        .doc(jobId)
        .snapshots()
        .map((doc) => doc.exists ? JobModel.fromSnapshot(doc) : null);
  }

  /// Published records are kept for history; the rules allow only staff to
  /// delete jobs. Clients close a job instead.
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
  Future<void> acceptJob(
    String jobId,
    String workerId,
    String workerName,
  ) async {
    try {
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc(jobId);
      final jobDoc = await jobRef.get();
      final data = jobDoc.data() ?? {};
      final clientId = data['clientId'] as String?;
      final title = data['title'] as String? ?? 'Job';

      final batch = _firestore.batch();
      batch.update(jobRef, {
        'status': 'assigned',
        'selectedWorkerId': workerId,
        'selectedWorkerName': workerName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (clientId != null && clientId.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': clientId,
          'title': 'Job Accepted ✅',
          'body': '$workerName accepted "$title".',
          'payload': {'jobId': jobId},
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to accept job: $e');
    }
  }

  @override
  Future<void> rejectJob(String jobId) async {
    try {
      final jobRef = _firestore.collection(FirestorePaths.jobs).doc(jobId);
      final jobDoc = await jobRef.get();
      final data = jobDoc.data() ?? {};
      final clientId = data['clientId'] as String?;
      final title = data['title'] as String? ?? 'Job';

      final batch = _firestore.batch();
      // Remove selected worker and set to open if it was a direct request
      batch.update(jobRef, {
        'status':
            'cancelled', // Or open, but cancelled is safer for rejected direct request
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (clientId != null && clientId.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': clientId,
          'title': 'Job Rejected ❌',
          'body': 'Your request for "$title" was declined.',
          'payload': {'jobId': jobId},
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to reject job: $e');
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
            'body':
                ' "$title" has been completed. Don\'t forget to leave a review!',
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
    throw ServerException(
      'Payments are not configured yet. No payment was taken.',
    );
  }

  @override
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.jobs)
          .doc(jobId)
          .get();
      if (!doc.exists) return null;
      return JobModel.fromSnapshot(doc);
    } catch (e) {
      throw ServerException('Failed to fetch job details: $e');
    }
  }

  @override
  Stream<List<JobModel>> getOpenJobs() {
    final query = _firestore
        .collection(FirestorePaths.jobs)
        .where('status', isEqualTo: 'open')
        // Public jobs only; direct requests are visible to their worker alone.
        .where('selectedWorkerId', isNull: true)
        .orderBy('createdAt', descending: true);
    return _watchCachedJobs(query, 'jobs:open');
  }

  @override
  Stream<List<JobModel>> getJobsByClient(String clientId) {
    final query = _firestore
        .collection(FirestorePaths.jobs)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true);
    return _watchCachedJobs(query, 'jobs:client:$clientId');
  }

  @override
  Stream<List<JobModel>> getJobsByCategory(String categoryId) {
    final query = _firestore
        .collection(FirestorePaths.jobs)
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'open')
        .where('selectedWorkerId', isNull: true)
        .orderBy('createdAt', descending: true);
    return _watchCachedJobs(query, 'jobs:category:$categoryId');
  }

  Stream<List<JobModel>> _watchCachedJobs(
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
            return JobModel.fromMap(id, record);
          })
          .toList();
    }

    try {
      await for (final snapshot in query.snapshots()) {
        final records = snapshot.docs
            .map((doc) => {...doc.data(), '__docId': doc.id})
            .toList();
        await OfflineCacheService.save(cacheKey, records);
        yield snapshot.docs.map(JobModel.fromSnapshot).toList();
      }
    } catch (_) {
      if (cached == null) rethrow;
    }
  }

  @override
  Stream<List<JobModel>> getDirectRequests(String workerId) {
    final query = _firestore
        .collection(FirestorePaths.jobs)
        .where('selectedWorkerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true);
    return _watchCachedJobs(query, 'jobs:worker-requests:$workerId');
  }
}

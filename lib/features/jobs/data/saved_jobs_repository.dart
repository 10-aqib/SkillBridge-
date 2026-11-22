import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';

/// A bookmarked job (Phase G6): a small snapshot for the list; the job
/// itself is opened (and checked for being still open) from its id.
class SavedJob {
  const SavedJob({required this.jobId, required this.title, this.city = '', this.budgetMin, this.budgetMax, this.budgetType = '', this.savedAt});
  final String jobId;
  final String title;
  final String city;
  final num? budgetMin;
  final num? budgetMax;
  final String budgetType;
  final DateTime? savedAt;

  factory SavedJob.fromMap(String id, Map<String, dynamic> d) => SavedJob(
        jobId: id,
        title: d['title'] is String ? d['title'] as String : '',
        city: d['city'] is String ? d['city'] as String : '',
        budgetMin: d['budgetMin'] is num ? d['budgetMin'] as num : null,
        budgetMax: d['budgetMax'] is num ? d['budgetMax'] as num : null,
        budgetType: d['budgetType'] is String ? d['budgetType'] as String : '',
        savedAt: d['savedAt'] is Timestamp ? (d['savedAt'] as Timestamp).toDate() : null,
      );
}

/// A worker's saved jobs in `users/{uid}/savedJobs/{jobId}` (owner only,
/// rules); kept across sessions and devices.
abstract class SavedJobsStore {
  Stream<List<SavedJob>> watch(String uid);
  Future<void> save(String uid, JobEntity job);
  Future<void> remove(String uid, String jobId);
}

class FirestoreSavedJobsStore implements SavedJobsStore {
  FirestoreSavedJobsStore(this._db);
  final FirebaseFirestore _db;

  /// Newest first; enough for anyone's bookmarks.
  static const limit = 200;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db.collection('users').doc(uid).collection('savedJobs');

  @override
  Stream<List<SavedJob>> watch(String uid) => _col(uid)
      .orderBy('savedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => [for (final d in s.docs) SavedJob.fromMap(d.id, d.data())]);

  @override
  Future<void> save(String uid, JobEntity job) => _col(uid).doc(job.id).set({
        'jobId': job.id,
        'title': job.title.length > 200 ? job.title.substring(0, 200) : job.title,
        'city': job.city.length > 80 ? job.city.substring(0, 80) : job.city,
        'budgetMin': job.budgetMin,
        'budgetMax': job.budgetMax,
        'budgetType': job.budgetType,
        'savedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> remove(String uid, String jobId) => _col(uid).doc(jobId).delete();
}

final savedJobsStoreProvider = Provider<SavedJobsStore>((ref) => FirestoreSavedJobsStore(ref.watch(firestoreProvider)));

/// The signed-in person's saved jobs (empty when signed out).
final savedJobsProvider = StreamProvider<List<SavedJob>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(savedJobsStoreProvider).watch(uid);
});

/// Ids of saved jobs, for bookmark buttons.
final savedJobIdsProvider = Provider<Set<String>>((ref) => {for (final j in ref.watch(savedJobsProvider).value ?? const <SavedJob>[]) j.jobId});

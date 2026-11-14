import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';

/// One server page: the jobs Firestore returned and where to continue.
class JobFeedRawPage {
  const JobFeedRawPage({required this.items, required this.cursor, required this.exhausted});
  final List<JobEntity> items;
  final Object? cursor;
  final bool exhausted;
}

/// Runs a [JobFeedPlan] against the backend, one page at a time.
abstract class JobFeedSource {
  Future<JobFeedRawPage> fetch(JobFeedPlan plan, {Object? cursor, required int limit});
}

class FirestoreJobFeedSource implements JobFeedSource {
  FirestoreJobFeedSource(this._firestore);
  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> buildQuery(JobFeedPlan plan) {
    Query<Map<String, dynamic>> q = _firestore.collection(FirestorePaths.jobs);
    plan.equals.forEach((field, value) {
      q = value == null ? q.where(field, isNull: true) : q.where(field, isEqualTo: value);
    });
    final contains = plan.arrayContains;
    if (contains != null) q = q.where(contains.key, arrayContains: contains.value);
    final any = plan.arrayContainsAny;
    if (any != null) q = q.where(any.key, arrayContainsAny: any.value);
    if (plan.createdAfter != null) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(plan.createdAfter!));
    }
    return q.orderBy(plan.orderBy, descending: plan.descending);
  }

  @override
  Future<JobFeedRawPage> fetch(JobFeedPlan plan, {Object? cursor, required int limit}) async {
    var q = buildQuery(plan).limit(limit);
    if (cursor is DocumentSnapshot) q = q.startAfterDocument(cursor);
    final snap = await q.get();
    return JobFeedRawPage(
      items: snap.docs.map(JobModel.fromSnapshot).toList(),
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
      exhausted: snap.docs.length < limit,
    );
  }
}

/// A page of the job feed after the plan's in-app checks.
class JobFeedPage {
  const JobFeedPage({required this.items, required this.cursor, required this.hasMore});
  final List<JobEntity> items;
  final Object? cursor;
  final bool hasMore;
}

/// Pages through matching jobs. When the plan has checks Firestore couldn't
/// apply, it keeps reading further server pages (up to [maxServerPages] per
/// call) until it has [pageSize] matches, so results come from all jobs,
/// not just the ones already on screen.
class JobFeedPager {
  JobFeedPager(this.source, {this.pageSize = 15, this.maxServerPages = 4});
  final JobFeedSource source;
  final int pageSize;
  final int maxServerPages;

  Future<JobFeedPage> load(JobFeedPlan plan, {Object? cursor}) async {
    final found = <JobEntity>[];
    var next = cursor;
    for (var i = 0; i < maxServerPages; i++) {
      final page = await source.fetch(plan, cursor: next, limit: pageSize);
      next = page.cursor;
      found.addAll(plan.hasClientChecks ? page.items.where(plan.matches) : page.items);
      if (page.exhausted) return JobFeedPage(items: found, cursor: next, hasMore: false);
      if (found.length >= pageSize || !plan.hasClientChecks) break;
    }
    return JobFeedPage(items: found, cursor: next, hasMore: true);
  }
}

final jobFeedSourceProvider = Provider<JobFeedSource>((ref) {
  return FirestoreJobFeedSource(ref.watch(firestoreProvider));
});

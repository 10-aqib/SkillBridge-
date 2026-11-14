import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/jobs/data/job_feed_source.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';

/// In-memory stand-in for Firestore that applies the same server-side parts
/// of a [JobFeedPlan] (equality, array filters, date range, order, cursor).
/// The plan's per-page checks are deliberately NOT applied here, so tests
/// prove the pager applies them. Mocked — not real Firebase.
class FakeJobFeedSource implements JobFeedSource {
  FakeJobFeedSource(this.jobs);
  List<JobEntity> jobs;
  final plans = <JobFeedPlan>[];
  int calls = 0;
  Object? failWith;

  Object? _field(JobEntity j, String f) => switch (f) {
        'status' => j.status.value,
        'selectedWorkerId' => (j.selectedWorkerId?.isEmpty ?? true) ? null : j.selectedWorkerId,
        'categoryId' => j.categoryId,
        'budgetType' => j.budgetType,
        'budgetBand' => BudgetBand.forJob(j.budgetMin, j.budgetMax).id,
        _ => throw ArgumentError(f),
      };

  @override
  Future<JobFeedRawPage> fetch(JobFeedPlan plan, {Object? cursor, required int limit}) async {
    calls++;
    plans.add(plan);
    if (failWith != null) throw failWith!;
    var list = jobs.where((j) {
      for (final e in plan.equals.entries) {
        if (_field(j, e.key) != e.value) return false;
      }
      final c = plan.arrayContains;
      if (c != null && !j.searchKeywords.contains(c.value)) return false;
      final any = plan.arrayContainsAny;
      if (any != null && !j.requiredSkills.any(any.value.contains)) return false;
      if (plan.createdAfter != null && j.createdAt.isBefore(plan.createdAfter!)) return false;
      return true;
    }).toList();
    int cmp(JobEntity a, JobEntity b) =>
        plan.orderBy == 'budgetMax' ? a.budgetMax.compareTo(b.budgetMax) : a.createdAt.compareTo(b.createdAt);
    list.sort((a, b) => plan.descending ? cmp(b, a) : cmp(a, b));
    final start = (cursor as int?) ?? 0;
    final page = list.skip(start).take(limit).toList();
    return JobFeedRawPage(items: page, cursor: start + page.length, exhausted: start + page.length >= list.length);
  }
}

FirebaseException firestoreError(String code) => FirebaseException(plugin: 'cloud_firestore', code: code);

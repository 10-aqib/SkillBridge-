import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_remote_datasource.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';

JobModel job({
  String title = 'Fix two kitchen sockets',
  String description = 'Two sockets spark when plugged in; please bring a tester.',
  String categoryId = 'electrician',
  String categoryName = 'Electrician',
  List<String> skills = const ['House wiring'],
  double budgetMin = 2000,
  double budgetMax = 3000,
  String budgetType = 'fixed',
  JobStatus status = JobStatus.open,
  String? selectedWorkerId,
  List<String> keywords = const [],
  DateTime? createdAt,
}) =>
    JobModel(
      id: 'j1',
      clientId: 'client_1',
      clientName: 'Ayesha Khan',
      title: title,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      requiredSkills: skills,
      jobType: JobType.temporary,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      budgetType: budgetType,
      address: 'Gulberg',
      city: 'Lahore',
      status: status,
      urgency: 'within_3_days',
      images: const [],
      totalProposals: 0,
      selectedWorkerId: selectedWorkerId,
      createdAt: createdAt ?? DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      searchKeywords: keywords,
    );

void main() {
  group('search keywords', () {
    final kw = JobSearchIndex.keywordsFor(
      title: 'Fix two kitchen sockets',
      categoryName: 'Electrician',
      categoryId: 'electrician',
      skills: ['House wiring'],
      description: 'Sparks when plugged in. Bring a tester.',
      city: 'Lahore',
    );

    test('title, category and skills are searchable by prefix', () {
      expect(kw, containsAll(['kit', 'kitchen', 'soc', 'sockets', 'ele', 'elect', 'electrician', 'wir', 'wiring', 'house']));
    });

    test('Roman-Urdu category synonyms are included', () {
      expect(kw, containsAll(['bijli', 'wala']));
    });

    test('description and city words are whole words only; stop words skipped', () {
      expect(kw, containsAll(['sparks', 'tester', 'lahore']));
      expect(kw, isNot(contains('spa')));
      expect(kw, isNot(contains('the')));
      expect(kw, isNot(contains('a')));
    });

    test('never exceeds the size the rules allow', () {
      final long = List.generate(400, (i) => 'word$i').join(' ');
      expect(JobSearchIndex.keywordsFor(title: 'Long job', categoryName: 'Painter', description: long).length,
          lessThanOrEqualTo(JobSearchIndex.maxKeywords));
    });

    test('query tokens are normalised and deduplicated; longest goes to the server', () {
      final t = JobSearchIndex.queryTokens('  Kitchen, KITCHEN wiring!! the ');
      expect(t, ['kitchen', 'wiring']);
      expect(JobSearchIndex.serverToken(t), 'kitchen');
    });
  });

  group('budget bands', () {
    test('boundaries', () {
      expect(BudgetBand.forAmount(1999), BudgetBand.under2k);
      expect(BudgetBand.forAmount(2000), BudgetBand.from2kTo5k);
      expect(BudgetBand.forAmount(14999), BudgetBand.from5kTo15k);
      expect(BudgetBand.forAmount(50000), BudgetBand.over50k);
    });
    test('uses the top of the range, or the single amount', () {
      expect(BudgetBand.forJob(1000, 6000), BudgetBand.from5kTo15k);
      expect(BudgetBand.forJob(3000, 0), BudgetBand.from2kTo5k);
    });
  });

  group('feed plan', () {
    final now = DateTime(2026, 11, 9, 12);

    test('always limited to public, open jobs', () {
      final p = JobFeedPlan.of(const JobFeedQuery());
      expect(p.equals, {'status': 'open', 'selectedWorkerId': null});
      expect(p.orderBy, 'createdAt');
      expect(p.descending, isTrue);
      expect(p.hasClientChecks, isFalse);
    });

    test('category, budget band and rate type are server filters', () {
      final p = JobFeedPlan.of(const JobFeedQuery(
        categoryId: 'plumber',
        budgetBand: BudgetBand.from2kTo5k,
        budgetType: 'hourly',
        sort: JobSort.budgetLow,
      ));
      expect(p.equals, containsPair('categoryId', 'plumber'));
      expect(p.equals, containsPair('budgetBand', '2k_5k'));
      expect(p.equals, containsPair('budgetType', 'hourly'));
      expect(p.orderBy, 'budgetMax');
      expect(p.descending, isFalse);
    });

    test('search: longest word on the server, other words checked per page', () {
      final p = JobFeedPlan.of(const JobFeedQuery(text: 'kitchen wiring'));
      expect(p.arrayContains, isA<MapEntry<String, String>>().having((e) => e.value, 'value', 'kitchen'));
      expect(p.clientTokens, ['wiring']);
    });

    test('skills alone are a server array-contains-any (max 10)', () {
      final skills = {for (var i = 0; i < 12; i++) 'skill $i'};
      final p = JobFeedPlan.of(JobFeedQuery(skills: skills));
      expect(p.arrayContainsAny!.value.length, 10);
      expect(p.clientSkills, isEmpty);
    });

    test('search plus skills: skills move to the per-page check', () {
      final p = JobFeedPlan.of(const JobFeedQuery(text: 'socket', skills: {'House wiring'}));
      expect(p.arrayContains!.key, 'searchKeywords');
      expect(p.arrayContainsAny, isNull);
      expect(p.clientSkills, {'House wiring'});
    });

    test('recency is a server range with date sorts, a per-page check with budget sorts', () {
      final byDate = JobFeedPlan.of(const JobFeedQuery(postedWithin: JobPostedWithin.week), now: now);
      expect(byDate.createdAfter, now.subtract(const Duration(days: 7)));
      expect(byDate.clientCreatedAfter, isNull);
      final byBudget = JobFeedPlan.of(const JobFeedQuery(postedWithin: JobPostedWithin.week, sort: JobSort.budgetHigh), now: now);
      expect(byBudget.createdAfter, isNull);
      expect(byBudget.clientCreatedAfter, now.subtract(const Duration(days: 7)));
    });

    test('per-page checks match what the query asked for', () {
      final p = JobFeedPlan.of(
        const JobFeedQuery(text: 'kitchen wiring', skills: {'House wiring'}, postedWithin: JobPostedWithin.week, sort: JobSort.budgetLow),
        now: now,
      );
      expect(p.matches(job(keywords: ['kitchen', 'wiring'], createdAt: DateTime(2026, 11, 8))), isTrue);
      expect(p.matches(job(keywords: ['kitchen'], createdAt: DateTime(2026, 11, 8))), isFalse, reason: 'missing a word');
      expect(p.matches(job(keywords: ['kitchen', 'wiring'], skills: ['Pipe fitting'], createdAt: DateTime(2026, 11, 8))), isFalse);
      expect(p.matches(job(keywords: ['kitchen', 'wiring'], createdAt: DateTime(2026, 10, 1))), isFalse, reason: 'too old');
    });
  });

  group('feed query', () {
    test('filter count, equality and clear-all keep search and sort', () {
      const q = JobFeedQuery(
        text: 'tap',
        categoryId: 'plumber',
        skills: {'Leak repair'},
        postedWithin: JobPostedWithin.day,
        sort: JobSort.oldest,
      );
      expect(q.activeFilterCount, 3);
      expect(q, const JobFeedQuery(text: 'tap', categoryId: 'plumber', skills: {'Leak repair'}, postedWithin: JobPostedWithin.day, sort: JobSort.oldest));
      expect(q.clearFilters(), const JobFeedQuery(text: 'tap', sort: JobSort.oldest));
      expect(q.copyWith(categoryId: () => null).categoryId, isNull);
    });
  });

  group('job model writes', () {
    test('a new job: owner, open status, empty counters and server timestamps', () {
      final m = job().toCreateMap();
      expect(m['clientId'], 'client_1');
      expect(m['status'], 'open');
      expect(m['totalProposals'], 0);
      expect(m['isPaid'], isFalse);
      expect(m['selectedWorkerId'], isNull);
      expect(m['createdAt'], isA<FieldValue>());
      expect(m['updatedAt'], isA<FieldValue>());
      expect(m['budgetBand'], '2k_5k');
      expect(m['searchKeywords'], containsAll(['kitchen', 'sockets']));
    });

    test('an edit sends content only — never ownership, status, counters or payment', () {
      final m = job().toEditMap();
      for (final protected in ['clientId', 'createdAt', 'status', 'totalProposals', 'isPaid', 'selectedWorkerId', 'selectedWorkerName']) {
        expect(m.containsKey(protected), isFalse, reason: protected);
      }
      expect(m['title'], 'Fix two kitchen sockets');
      expect(m['searchKeywords'], isNotEmpty);
    });

    test('public-open flag excludes direct requests and closed jobs', () {
      expect(job().isPublicOpen, isTrue);
      expect(job(selectedWorkerId: 'w1').isPublicOpen, isFalse);
      expect(job(status: JobStatus.cancelled).isPublicOpen, isFalse);
    });

    test('contract status changes map to real job statuses', () {
      expect(jobStatusForContractStatus('active'), 'in_progress');
      expect(jobStatusForContractStatus('rejected'), 'cancelled');
      expect(jobStatusForContractStatus('completed'), 'completed');
    });
  });
}

import 'package:skill_bridge/core/utils/pakistani_trade_synonyms.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';

/// Search keywords stored on each job (`searchKeywords`).
///
/// Firestore has no full-text search, so a job carries lower-case tokens that
/// a single `array-contains` query can match: every word of the title,
/// category (plus its Roman-Urdu synonyms) and skills with its prefixes from
/// 3 letters ("elec", "elect"…), and whole description words. Jobs created
/// before this field existed have no keywords and only appear in unfiltered
/// browsing until they are edited.
class JobSearchIndex {
  JobSearchIndex._();

  /// Firestore rules cap the list at this size.
  static const int maxKeywords = 300;
  static const int _maxPrefix = 12;

  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'for', 'of', 'to', 'in', 'on', 'at', 'with', 'my', 'our', 'is', 'are',
    'be', 'it', 'this', 'that', 'need', 'needed', 'required', 'want', 'please', 'urgent', 'job', 'work',
    'ka', 'ki', 'ke', 'hai', 'aur', 'se', 'ko', 'mein', 'me', 'kaam', 'chahiye',
  };

  static final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  /// Lower-case words worth indexing or searching for.
  static List<String> words(String text) => text
      .toLowerCase()
      .split(_separators)
      .where((w) => w.length >= 2 && !_stopWords.contains(w))
      .toList();

  static List<String> keywordsFor({
    required String title,
    required String categoryName,
    String categoryId = '',
    List<String> skills = const [],
    String description = '',
    String city = '',
  }) {
    final out = <String>{};
    void addWithPrefixes(String word) {
      final end = word.length < _maxPrefix ? word.length : _maxPrefix;
      for (var i = 3; i <= end; i++) {
        out.add(word.substring(0, i));
      }
      out.add(word);
    }

    final synonyms = <String>[
      for (final entry in PakistaniTradeSynonyms.categorySynonyms.entries)
        if (entry.key.toLowerCase() == categoryName.toLowerCase() ||
            entry.key.toLowerCase().replaceAll(' ', '_') == categoryId)
          ...entry.value,
    ];
    for (final w in [
      ...words(title),
      ...words(categoryName),
      ...words(categoryId.replaceAll('_', ' ')),
      for (final s in skills) ...words(s),
      for (final s in synonyms) ...words(s),
    ]) {
      addWithPrefixes(w);
    }
    for (final w in [...words(city), ...words(description)]) {
      if (out.length >= maxKeywords) break;
      if (w.length >= 3) out.add(w);
    }
    return out.take(maxKeywords).toList();
  }

  /// Search terms from what the person typed (deduplicated, in order).
  static List<String> queryTokens(String query) {
    final seen = <String>{};
    return [for (final w in words(query)) if (seen.add(w)) w];
  }

  /// The most selective term goes to the server (longest wins).
  static String serverToken(List<String> tokens) =>
      tokens.reduce((a, b) => b.length > a.length ? b : a);
}

/// Budget ranges a worker can filter by. Stored on each job as `budgetBand`
/// (from the top of its budget), because Firestore cannot sort by date while
/// range-filtering on a different field.
enum BudgetBand {
  under2k('under_2k', 0, 2000),
  from2kTo5k('2k_5k', 2000, 5000),
  from5kTo15k('5k_15k', 5000, 15000),
  from15kTo50k('15k_50k', 15000, 50000),
  over50k('over_50k', 50000, null);

  const BudgetBand(this.id, this.min, this.max);
  final String id;
  final int min;
  final int? max; // exclusive; null = no upper limit

  static BudgetBand forAmount(num amount) {
    for (final b in values) {
      if (b.max == null || amount < b.max!) return b;
    }
    return over50k;
  }

  static BudgetBand forJob(num budgetMin, num budgetMax) => forAmount(budgetMax > 0 ? budgetMax : budgetMin);

  static BudgetBand? fromId(String? id) {
    for (final b in values) {
      if (b.id == id) return b;
    }
    return null;
  }
}

enum JobPostedWithin {
  any(null),
  day(Duration(days: 1)),
  threeDays(Duration(days: 3)),
  week(Duration(days: 7)),
  month(Duration(days: 30));

  const JobPostedWithin(this.window);
  final Duration? window;
}

enum JobSort {
  newest('createdAt', true),
  oldest('createdAt', false),
  budgetLow('budgetMax', false),
  budgetHigh('budgetMax', true);

  const JobSort(this.field, this.descending);
  final String field;
  final bool descending;
  bool get byDate => field == 'createdAt';
}

/// What a worker asked the job feed for.
class JobFeedQuery {
  const JobFeedQuery({
    this.text = '',
    this.categoryId,
    this.budgetBand,
    this.budgetType,
    this.skills = const {},
    this.postedWithin = JobPostedWithin.any,
    this.sort = JobSort.newest,
  });

  final String text;
  final String? categoryId;
  final BudgetBand? budgetBand;
  final String? budgetType; // fixed | hourly | daily
  final Set<String> skills;
  final JobPostedWithin postedWithin;
  final JobSort sort;

  /// Firestore allows at most 10 values in array-contains-any.
  static const int maxSkills = 10;

  int get activeFilterCount =>
      (categoryId != null ? 1 : 0) +
      (budgetBand != null ? 1 : 0) +
      (budgetType != null ? 1 : 0) +
      skills.length +
      (postedWithin != JobPostedWithin.any ? 1 : 0);

  bool get hasSearch => JobSearchIndex.queryTokens(text).isNotEmpty;

  JobFeedQuery copyWith({
    String? text,
    String? Function()? categoryId,
    BudgetBand? Function()? budgetBand,
    String? Function()? budgetType,
    Set<String>? skills,
    JobPostedWithin? postedWithin,
    JobSort? sort,
  }) =>
      JobFeedQuery(
        text: text ?? this.text,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        budgetBand: budgetBand != null ? budgetBand() : this.budgetBand,
        budgetType: budgetType != null ? budgetType() : this.budgetType,
        skills: skills ?? this.skills,
        postedWithin: postedWithin ?? this.postedWithin,
        sort: sort ?? this.sort,
      );

  /// Same search text and sort, no filters.
  JobFeedQuery clearFilters() => JobFeedQuery(text: text, sort: sort).normalized();

  /// Budget sorts compare one pay type at a time: a fixed price and an hourly
  /// rate are different units, so ranking them together would mislead. A
  /// budget sort without a pay type uses fixed-price jobs.
  JobFeedQuery normalized() =>
      sort.byDate || budgetType != null ? this : copyWith(budgetType: () => 'fixed');

  /// Removing the pay type while sorting by budget falls back to newest.
  JobFeedQuery withoutBudgetType() =>
      copyWith(budgetType: () => null, sort: sort.byDate ? sort : JobSort.newest);

  @override
  bool operator ==(Object other) =>
      other is JobFeedQuery &&
      other.text == text &&
      other.categoryId == categoryId &&
      other.budgetBand == budgetBand &&
      other.budgetType == budgetType &&
      other.skills.length == skills.length &&
      other.skills.containsAll(skills) &&
      other.postedWithin == postedWithin &&
      other.sort == sort;

  @override
  int get hashCode =>
      Object.hash(text, categoryId, budgetBand, budgetType, Object.hashAllUnordered(skills), postedWithin, sort);
}

/// How a [JobFeedQuery] runs: what Firestore filters on, and the few checks
/// Firestore cannot combine in one query, which are applied to each fetched
/// page while paging continues through all matching jobs.
class JobFeedPlan {
  JobFeedPlan._({
    required this.equals,
    required this.orderBy,
    required this.descending,
    this.arrayContains,
    this.arrayContainsAny,
    this.createdAfter,
    this.clientTokens = const [],
    this.clientSkills = const {},
    this.clientCreatedAfter,
  });

  /// Always includes `status == open` and `selectedWorkerId == null`: only
  /// public, open jobs (the rules allow workers to read nothing else).
  final Map<String, Object?> equals;
  final String orderBy;
  final bool descending;
  final MapEntry<String, String>? arrayContains;
  final MapEntry<String, List<String>>? arrayContainsAny;
  final DateTime? createdAfter;

  final List<String> clientTokens;
  final Set<String> clientSkills;
  final DateTime? clientCreatedAfter;

  bool get hasClientChecks => clientTokens.isNotEmpty || clientSkills.isNotEmpty || clientCreatedAfter != null;

  factory JobFeedPlan.of(JobFeedQuery q, {DateTime? now}) {
    final equals = <String, Object?>{
      'status': 'open',
      'selectedWorkerId': null,
      if (q.categoryId != null) 'categoryId': q.categoryId,
      if (q.budgetBand != null) 'budgetBand': q.budgetBand!.id,
      if (q.budgetType != null) 'budgetType': q.budgetType,
    };
    final tokens = JobSearchIndex.queryTokens(q.text);
    final skills = q.skills.take(JobFeedQuery.maxSkills).toList();
    final window = q.postedWithin.window;
    final cutoff = window == null ? null : (now ?? DateTime.now()).subtract(window);

    // One array filter per query: search wins; skills are then checked per page.
    final serverToken = tokens.isEmpty ? null : JobSearchIndex.serverToken(tokens);
    return JobFeedPlan._(
      equals: equals,
      orderBy: q.sort.field,
      descending: q.sort.descending,
      arrayContains: serverToken == null ? null : MapEntry('searchKeywords', serverToken),
      arrayContainsAny: serverToken == null && skills.isNotEmpty ? MapEntry('requiredSkills', skills) : null,
      // A date range can't be combined with a budget sort in Firestore.
      createdAfter: q.sort.byDate ? cutoff : null,
      clientTokens: [for (final t in tokens) if (t != serverToken) t],
      clientSkills: serverToken != null ? skills.toSet() : const {},
      clientCreatedAfter: q.sort.byDate ? null : cutoff,
    );
  }

  /// The checks Firestore couldn't apply.
  bool matches(JobEntity job) {
    if (clientTokens.isNotEmpty && !clientTokens.every(job.searchKeywords.contains)) return false;
    if (clientSkills.isNotEmpty && !job.requiredSkills.any(clientSkills.contains)) return false;
    if (clientCreatedAfter != null && job.createdAt.isBefore(clientCreatedAfter!)) return false;
    return true;
  }
}

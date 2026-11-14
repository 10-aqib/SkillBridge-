import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/features/jobs/data/job_feed_source.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';

enum JobFeedError { network, missingIndex, permission, other }

class JobFeedState {
  const JobFeedState({
    this.query = const JobFeedQuery(),
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.hasMore = false,
    this.cursor,
  });

  final JobFeedQuery query;
  final List<JobEntity> items;
  final bool loading;
  final bool loadingMore;
  final JobFeedError? error;
  final bool hasMore;
  final Object? cursor;

  JobFeedState copyWith({
    JobFeedQuery? query,
    List<JobEntity>? items,
    bool? loading,
    bool? loadingMore,
    JobFeedError? Function()? error,
    bool? hasMore,
    Object? Function()? cursor,
  }) =>
      JobFeedState(
        query: query ?? this.query,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error != null ? error() : this.error,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor != null ? cursor() : this.cursor,
      );
}

JobFeedError jobFeedErrorOf(Object e) {
  if (e is FirebaseException) {
    return switch (e.code) {
      'failed-precondition' => JobFeedError.missingIndex,
      'permission-denied' => JobFeedError.permission,
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' => JobFeedError.network,
      _ => JobFeedError.other,
    };
  }
  return JobFeedError.other;
}

/// Worker job feed: real Firestore pages for the current search, filters and
/// sort. A newer request always replaces an older one still in flight.
class JobFeedController extends Notifier<JobFeedState> {
  int _generation = 0;

  JobFeedPager get _pager => JobFeedPager(ref.read(jobFeedSourceProvider));

  @override
  JobFeedState build() {
    Future.microtask(refresh);
    return const JobFeedState();
  }

  Future<void> setQuery(JobFeedQuery query) async {
    query = query.normalized();
    if (query == state.query && !state.loading && state.error == null) return;
    state = state.copyWith(query: query);
    await refresh();
  }

  Future<void> refresh() async {
    final gen = ++_generation;
    state = state.copyWith(loading: true, loadingMore: false, error: () => null);
    try {
      final page = await _pager.load(JobFeedPlan.of(state.query));
      if (gen != _generation) return;
      state = state.copyWith(items: page.items, loading: false, hasMore: page.hasMore, cursor: () => page.cursor);
    } catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(items: const [], loading: false, hasMore: false, error: () => jobFeedErrorOf(e));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final gen = _generation;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _pager.load(JobFeedPlan.of(state.query), cursor: state.cursor);
      if (gen != _generation) return;
      final seen = {for (final j in state.items) j.id};
      state = state.copyWith(
        items: [...state.items, ...page.items.where((j) => seen.add(j.id))],
        loadingMore: false,
        hasMore: page.hasMore,
        cursor: () => page.cursor,
      );
    } catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(loadingMore: false, error: () => jobFeedErrorOf(e));
    }
  }
}

final jobFeedControllerProvider =
    NotifierProvider.autoDispose<JobFeedController, JobFeedState>(JobFeedController.new);

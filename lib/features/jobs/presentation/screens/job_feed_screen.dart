import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_feed_controller.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Worker job discovery: real open jobs from Firestore with search, filters,
/// sorting and paging.
class JobFeedScreen extends ConsumerStatefulWidget {
  const JobFeedScreen({super.key});

  @override
  ConsumerState<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends ConsumerState<JobFeedScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        ref.read(jobFeedControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  JobFeedController get _feed => ref.read(jobFeedControllerProvider.notifier);
  JobFeedQuery get _query => ref.read(jobFeedControllerProvider).query;

  void _onSearchChanged(String text) {
    setState(() {}); // clear button visibility
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _feed.setQuery(_query.copyWith(text: text)));
  }

  void _submitSearch(String text) {
    _debounce?.cancel();
    _feed.setQuery(_query.copyWith(text: text));
  }

  void _clearSearch() {
    _search.clear();
    _submitSearch('');
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<JobFeedQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FilterSheet(initial: _query),
    );
    if (result != null) _feed.setQuery(result);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    // List centred at reading width, matching the header above it.
    final side = math.max(edge, (MediaQuery.sizeOf(context).width - SbLayout.formMaxWidth) / 2);
    final state = ref.watch(jobFeedControllerProvider);
    final q = state.query;

    final chips = <Widget>[
      if (q.categoryId != null)
        _ActiveChip(
          label: jobCategoryLabel(context, q.categoryId!, q.categoryId!),
          onRemove: () => _feed.setQuery(q.copyWith(categoryId: () => null, skills: const {})),
        ),
      if (q.budgetBand != null)
        _ActiveChip(label: budgetBandLabel(l, q.budgetBand!), onRemove: () => _feed.setQuery(q.copyWith(budgetBand: () => null))),
      if (q.budgetType != null)
        _ActiveChip(label: budgetTypeLabel(l, q.budgetType!), onRemove: () => _feed.setQuery(q.withoutBudgetType())),
      for (final s in q.skills)
        _ActiveChip(label: s, onRemove: () => _feed.setQuery(q.copyWith(skills: {...q.skills}..remove(s)))),
      if (q.postedWithin != JobPostedWithin.any)
        _ActiveChip(
          label: postedWithinLabel(l, q.postedWithin),
          onRemove: () => _feed.setQuery(q.copyWith(postedWithin: JobPostedWithin.any)),
        ),
    ];

    Widget body;
    if (state.loading) {
      body = SliverList.separated(
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: SbSpace.s3),
        itemBuilder: (_, _) => const JobCardSkeleton(),
      );
    } else if (state.error != null && state.items.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: SbStateView(
          kind: state.error == JobFeedError.network ? SbStateKind.offline : SbStateKind.error,
          title: l.jobFeedErrorTitle,
          message: switch (state.error!) {
            JobFeedError.network => l.errNetwork,
            JobFeedError.missingIndex => l.jobFeedErrorIndex,
            JobFeedError.permission => l.jobFeedErrorPermission,
            JobFeedError.other => l.errGeneric,
          },
          actionLabel: l.tryAgain,
          onAction: _feed.refresh,
        ),
      );
    } else if (state.items.isEmpty) {
      final narrowed = q.hasSearch || q.activeFilterCount > 0;
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: SbStateView(
          kind: SbStateKind.empty,
          title: narrowed ? l.jobFeedNoMatchTitle : l.jobFeedEmptyTitle,
          message: narrowed ? l.jobFeedNoMatchBody : l.jobFeedEmptyBody,
          actionLabel: narrowed ? l.jobFeedClearAll : null,
          onAction: narrowed
              ? () {
                  _search.clear();
                  _feed.setQuery(JobFeedQuery(sort: q.sort));
                }
              : null,
        ),
      );
    } else {
      body = SliverList.builder(
        itemCount: state.items.length + 1,
        itemBuilder: (context, i) {
          if (i == state.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: SbSpace.s5),
              child: Center(
                child: state.loadingMore
                    ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : state.error != null
                        ? TextButton(onPressed: _feed.loadMore, child: Text(l.jobFeedLoadMoreFailed))
                        : state.hasMore
                            ? TextButton(onPressed: _feed.loadMore, child: Text(l.jobFeedLoadMore))
                            : Text(l.jobFeedEnd, style: t.bodySmall),
              ),
            );
          }
          final job = state.items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: SbSpace.s3),
            child: JobListCard(
              job: job,
              showDetails: true,
              onTap: () => context.push(RouteNames.jobDetailsLocation(job.id), extra: job),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.jobFeedTitle), actions: [
        IconButton(
          tooltip: l.savedJobsTitle,
          icon: const Icon(Icons.bookmarks_outlined),
          onPressed: () => context.push(RouteNames.workerSavedJobsPath),
        ),
      ]),
      body: RefreshIndicator(
        onRefresh: _feed.refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(edge, SbSpace.s2, edge, SbSpace.s3),
              sliver: SliverToBoxAdapter(
                child: SbReadableWidth(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: _submitSearch,
                          decoration: InputDecoration(
                            hintText: l.jobFeedSearchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(tooltip: l.jobFeedClearSearch, icon: const Icon(Icons.close_rounded), onPressed: _clearSearch),
                          ),
                        ),
                      ),
                      const SizedBox(width: SbSpace.s2),
                      Badge(
                        isLabelVisible: q.activeFilterCount > 0,
                        label: Text('${q.activeFilterCount}'),
                        child: IconButton.outlined(
                          tooltip: l.jobFeedFilters,
                          icon: const Icon(Icons.tune_rounded),
                          onPressed: _openFilters,
                        ),
                      ),
                    ]),
                    const SizedBox(height: SbSpace.s3),
                    Row(children: [
                      Expanded(
                        child: Text(
                          state.loading ? l.jobFeedSearching : l.jobFeedShowing(state.items.length),
                          style: t.bodySmall,
                        ),
                      ),
                      Flexible(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: PopupMenuButton<JobSort>(
                            tooltip: l.jobFeedSort,
                            initialValue: q.sort,
                            onSelected: (s) => _feed.setQuery(q.copyWith(sort: s)),
                            itemBuilder: (_) => [
                              for (final s in JobSort.values) PopupMenuItem(value: s, child: Text(jobSortLabel(l, s))),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: SbSpace.s2),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.swap_vert_rounded, size: 18, color: c.primary),
                                const SizedBox(width: SbSpace.s1),
                                // A budget sort names its pay type: "Highest budget · Fixed price".
                                Flexible(
                                  child: Text(
                                    q.sort.byDate || q.budgetType == null
                                        ? jobSortLabel(l, q.sort)
                                        : l.jobSortBudgetWithin(jobSortLabel(l, q.sort), budgetTypeLabel(l, q.budgetType!)),
                                    style: t.labelLarge!.copyWith(color: c.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: SbSpace.s2),
                      Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        ...chips,
                        TextButton(onPressed: () => _feed.setQuery(q.clearFilters()), child: Text(l.jobFeedClearAll)),
                      ]),
                    ],
                  ]),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, SbSpace.s8),
              sliver: body,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => InputChip(
        label: Text(label),
        onDeleted: onRemove,
        deleteButtonTooltipMessage: context.l10n.jobFeedRemoveFilter(label),
      );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final JobFeedQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late JobFeedQuery q = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final skills = PakistanConstants.skillSuggestions[q.categoryId] ?? const <String>[];

    Widget group(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: SbSpace.s5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(title, style: t.titleSmall)),
            const SizedBox(height: SbSpace.s2),
            child,
          ]),
        );

    Widget wrap(List<Widget> children) => Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: children);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(SbSpace.s5, SbSpace.s4, SbSpace.s3, SbSpace.s2),
          child: Row(children: [
            Expanded(child: Text(l.jobFeedFilters, style: t.titleLarge)),
            TextButton(onPressed: () => setState(() => q = q.clearFilters()), child: Text(l.jobFeedClearAll)),
          ]),
        ),
        Expanded(
          child: ListView(controller: controller, padding: const EdgeInsets.symmetric(horizontal: SbSpace.s5), children: [
            group(
              l.jobFormCategoryLabel,
              wrap([
                for (final cat in PakistanConstants.categories)
                  ChoiceChip(
                    avatar: Icon(cat['icon'] as IconData, size: 18),
                    label: Text(context.isUrdu ? cat['urdu'] as String : cat['name'] as String),
                    selected: q.categoryId == cat['id'],
                    showCheckmark: false,
                    onSelected: (on) => setState(() => q = q.copyWith(
                          categoryId: () => on ? cat['id'] as String : null,
                          skills: const {},
                        )),
                  ),
              ]),
            ),
            group(
              l.jobFormSkillsLabel,
              skills.isEmpty
                  ? Text(l.jobFeedSkillsNeedCategory, style: t.bodySmall)
                  : wrap([
                      for (final s in skills)
                        FilterChip(
                          label: Text(s),
                          selected: q.skills.contains(s),
                          onSelected: (on) {
                            if (on && q.skills.length >= JobFeedQuery.maxSkills) return;
                            setState(() => q = q.copyWith(skills: on ? {...q.skills, s} : ({...q.skills}..remove(s))));
                          },
                        ),
                    ]),
            ),
            group(
              l.jobFeedBudget,
              wrap([
                for (final b in BudgetBand.values)
                  ChoiceChip(
                    label: Text(budgetBandLabel(l, b)),
                    selected: q.budgetBand == b,
                    onSelected: (on) => setState(() => q = q.copyWith(budgetBand: () => on ? b : null)),
                  ),
              ]),
            ),
            group(
              l.jobFormBudgetTypeLabel,
              wrap([
                for (final type in const ['fixed', 'hourly', 'daily'])
                  ChoiceChip(
                    label: Text(budgetTypeLabel(l, type)),
                    selected: q.budgetType == type,
                    onSelected: (on) => setState(() => q = on ? q.copyWith(budgetType: () => type) : q.withoutBudgetType()),
                  ),
              ]),
            ),
            group(
              l.jobFeedPosted,
              wrap([
                for (final p in JobPostedWithin.values)
                  ChoiceChip(
                    label: Text(postedWithinLabel(l, p)),
                    selected: q.postedWithin == p,
                    onSelected: (_) => setState(() => q = q.copyWith(postedWithin: p)),
                  ),
              ]),
            ),
            group(
              l.jobFeedSort,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                wrap([
                  for (final s in JobSort.values)
                    ChoiceChip(
                      label: Text(jobSortLabel(l, s)),
                      selected: q.sort == s,
                      onSelected: (_) => setState(() => q = q.copyWith(sort: s).normalized()),
                    ),
                ]),
                const SizedBox(height: SbSpace.s2),
                Text(l.jobFeedBudgetSortNote, style: t.bodySmall),
              ]),
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(SbSpace.s5, SbSpace.s2, SbSpace.s5, SbSpace.s3),
            child: SbButton(label: l.jobFeedShowResults, expand: true, onPressed: () => Navigator.pop(context, q)),
          ),
        ),
      ]),
    );
  }
}

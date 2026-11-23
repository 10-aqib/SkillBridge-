import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/features/proposals/presentation/widgets/proposal_ui.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

enum ReceivedTab { active, accepted, notSelected }

enum ReceivedSort { newest, oldest, price }

/// Which list a received proposal belongs in. Withdrawn ones are not shown to
/// the client: the worker took them back.
ReceivedTab? receivedTabOf(ProposalStatus s) => switch (s) {
      ProposalStatus.pending => ReceivedTab.active,
      ProposalStatus.accepted => ReceivedTab.accepted,
      ProposalStatus.rejected => ReceivedTab.notSelected,
      ProposalStatus.withdrawn => null,
    };

/// Price order only means something between proposals with the same rate
/// type, so proposals are grouped by rate type first (fixed, daily, hourly),
/// then by amount.
List<ProposalEntity> sortProposals(List<ProposalEntity> list, ReceivedSort sort) {
  const typeOrder = {'fixed': 0, 'daily': 1, 'hourly': 2};
  final out = [...list];
  switch (sort) {
    case ReceivedSort.newest:
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case ReceivedSort.oldest:
      out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case ReceivedSort.price:
      out.sort((a, b) {
        final t = (typeOrder[a.rateType] ?? 9).compareTo(typeOrder[b.rateType] ?? 9);
        return t != 0 ? t : a.proposedRate.compareTo(b.proposedRate);
      });
  }
  return out;
}

String _rateTypeTitle(AppLocalizations l, String type) => switch (type) {
      'hourly' => l.proposalRateHourly,
      'daily' => l.proposalRateDaily,
      _ => l.proposalRateFixed,
    };

/// The proposals a client received for one of their jobs.
class ReceivedProposalsScreen extends ConsumerStatefulWidget {
  const ReceivedProposalsScreen({super.key, required this.jobId, this.initialJob});
  final String jobId;
  final JobEntity? initialJob;

  @override
  ConsumerState<ReceivedProposalsScreen> createState() => _ReceivedProposalsScreenState();
}

class _ReceivedProposalsScreenState extends ConsumerState<ReceivedProposalsScreen> {
  ReceivedTab _tab = ReceivedTab.active;

  // The first load opens on a tab that has something in it (after a hire,
  // that is Accepted).
  bool _tabChosen = false;
  ReceivedSort _sort = ReceivedSort.newest;

  String _tabLabel(ReceivedTab t, int n) {
    final l = context.l10n;
    final name = switch (t) {
      ReceivedTab.active => l.proposalTabActive,
      ReceivedTab.accepted => l.proposalStatusAccepted,
      ReceivedTab.notSelected => l.proposalTabNotSelected,
    };
    return '$name · $n';
  }

  String _sortLabel(ReceivedSort s) {
    final l = context.l10n;
    return switch (s) {
      ReceivedSort.newest => l.proposalSortNewest,
      ReceivedSort.oldest => l.proposalSortOldest,
      ReceivedSort.price => l.proposalSortPrice,
    };
  }

  void _compare(List<ProposalEntity> active) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => _CompareSheet(proposals: active, controller: scroll),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    final me = ref.watch(currentUserProvider);
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));
    final job = jobAsync.hasError ? null : (jobAsync.value ?? (jobAsync.isLoading ? widget.initialJob : null));

    if (job == null || me == null || job.clientId != me.uid) {
      return Scaffold(
        appBar: AppBar(title: Text(l.receivedProposalsTitle)),
        body: jobAsync.isLoading && !jobAsync.hasError
            ? const Center(child: CircularProgressIndicator())
            : SbStateView(kind: SbStateKind.empty, title: l.jobUnavailableTitle, message: l.jobUnavailableBody),
      );
    }

    final proposals = ref.watch(jobProposalsStreamProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(title: Text(l.receivedProposalsTitle)),
      body: SbLoadSwitcher(
        loading: proposals.isLoading && !proposals.hasValue,
        child: proposals.when(
        loading: () => SbSkeletonList(item: const JobCardSkeleton(), count: 4, label: l.loading),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.receivedProposalsLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(jobProposalsStreamProvider(widget.jobId)),
        ),
        data: (raw) {
          final all = raw.where((p) => receivedTabOf(p.status) != null).toList();
          final counts = {for (final x in ReceivedTab.values) x: all.where((p) => receivedTabOf(p.status) == x).length};
          if (!_tabChosen && all.isNotEmpty) {
            _tabChosen = true;
            if (counts[_tab] == 0) _tab = ReceivedTab.values.firstWhere((t) => counts[t]! > 0);
          }
          final shown = sortProposals(all.where((p) => receivedTabOf(p.status) == _tab).toList(), _sort);
          final active = all.where((p) => p.status == ProposalStatus.pending).toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
            children: [
              SbReadableWidth(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // The job these proposals are for.
                  Container(
                    padding: const EdgeInsets.all(SbSpace.s4),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(SbRadius.card), border: Border.all(color: c.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      JobStatusBadge(status: job.status),
                      const SizedBox(height: SbSpace.s2),
                      Text(job.title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: SbSpace.s1),
                      Text(jobBudgetLabel(l, job), style: SbTypography.numeric(t.bodyMedium!)),
                      const SizedBox(height: SbSpace.s1),
                      Text(l.receivedProposalsCount(job.totalProposals), style: t.bodySmall),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => context.push(RouteNames.jobDetailsLocation(job.id), extra: job),
                        child: Text(l.proposalViewJob),
                      ),
                    ]),
                  ),
                  if (!job.isPublicOpen && active.isNotEmpty) ...[
                    const SizedBox(height: SbSpace.s3),
                    SbInlineBanner(message: l.proposalJobNotOpenNotice, tone: SbTone.warning),
                  ],
                  const SizedBox(height: SbSpace.s4),
                  if (all.isEmpty)
                    SbStateView(
                      kind: SbStateKind.empty,
                      compact: true,
                      title: l.receivedProposalsEmptyTitle,
                      message: job.isPublicOpen ? l.receivedProposalsEmptyBody : null,
                    )
                  else ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final x in ReceivedTab.values)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: SbSpace.s2),
                            child: ChoiceChip(
                              label: Text(_tabLabel(x, counts[x]!)),
                              selected: _tab == x,
                              onSelected: (_) => setState(() => _tab = x),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: SbSpace.s2),
                    Row(children: [
                      PopupMenuButton<ReceivedSort>(
                        tooltip: l.proposalSortTooltip,
                        initialValue: _sort,
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (_) => [
                          for (final s in ReceivedSort.values) PopupMenuItem(value: s, child: Text(_sortLabel(s))),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: SbSpace.s2),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.sort_rounded, size: 18, color: c.textSecondary),
                            const SizedBox(width: SbSpace.s1),
                            Text(_sortLabel(_sort), style: t.labelLarge),
                          ]),
                        ),
                      ),
                      const Spacer(),
                      if (active.length >= 2)
                        TextButton.icon(
                          icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                          label: Text(l.proposalCompare),
                          onPressed: () => _compare(active),
                        ),
                    ]),
                    if (_sort == ReceivedSort.price)
                      Padding(
                        padding: const EdgeInsets.only(bottom: SbSpace.s2),
                        child: Text(l.proposalPriceSortNote, style: t.bodySmall),
                      ),
                    const SizedBox(height: SbSpace.s2),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: SbSpace.s8),
                        child: Text(l.myProposalsTabEmpty, textAlign: TextAlign.center, style: t.bodyMedium),
                      ),
                    for (final p in shown) ...[
                      ReceivedProposalCard(proposal: p),
                      const SizedBox(height: SbSpace.s3),
                    ],
                  ],
                ]),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

/// One received proposal: who sent it (from their real profile), price,
/// duration, when, status and the start of the cover letter.
class ReceivedProposalCard extends StatelessWidget {
  const ReceivedProposalCard({super.key, required this.proposal});
  final ProposalEntity proposal;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final p = proposal;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    void open() => context.push(RouteNames.proposalDetailsLocation(p.id), extra: p);

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.card), side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(SbSpace.s4, SbSpace.s4, SbSpace.s4, SbSpace.s2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ProposalWorkerCard(proposal: p, compact: true)),
              const SizedBox(width: SbSpace.s2),
              ProposalStatusBadge(proposal: p),
            ]),
            const SizedBox(height: SbSpace.s3),
            Row(children: [
              Expanded(flex: 3, child: Text(proposalPriceLabel(l, p), style: SbTypography.numeric(t.titleSmall!))),
              const SizedBox(width: SbSpace.s2),
              Expanded(flex: 2, child: Text(p.estimatedDuration, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
            ]),
            const SizedBox(height: SbSpace.s2),
            Text(p.coverLetter, style: t.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: SbSpace.s2),
            Row(children: [
              Expanded(child: Text(l.proposalSentOn(date.format(p.createdAt)), style: t.bodySmall)),
              TextButton(onPressed: open, child: Text(l.proposalReviewAction)),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Side-by-side view of the active proposals, one table per rate type, so a
/// fixed price is never ranked against an hourly rate.
class _CompareSheet extends ConsumerWidget {
  const _CompareSheet({required this.proposals, required this.controller});
  final List<ProposalEntity> proposals;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    final sorted = sortProposals(proposals, ReceivedSort.price);
    final groups = <String, List<ProposalEntity>>{};
    for (final p in sorted) {
      groups.putIfAbsent(p.rateType, () => []).add(p);
    }

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(edge, 0, edge, SbSpace.s6),
      children: [
        Semantics(header: true, child: Text(l.proposalCompareTitle, style: t.titleLarge)),
        const SizedBox(height: SbSpace.s1),
        Text(l.proposalPriceSortNote, style: t.bodySmall),
        for (final entry in groups.entries) ...[
          const SizedBox(height: SbSpace.s4),
          Text(_rateTypeTitle(l, entry.key), style: t.titleSmall),
          const SizedBox(height: SbSpace.s2),
          for (final p in entry.value)
            Builder(builder: (context) {
              final worker = ref.watch(workerProfileProvider(p.workerId)).value;
              final wp = worker?.workerProfile;
              final reviews = wp?.totalReviews ?? 0;
              return InkWell(
                borderRadius: BorderRadius.circular(SbRadius.control),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(RouteNames.proposalDetailsLocation(p.id), extra: p);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: SbSpace.s2),
                  padding: const EdgeInsets.all(SbSpace.s3),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(SbRadius.control), border: Border.all(color: c.border)),
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(worker?.formattedDisplayName ?? p.workerName, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          [
                            if (reviews > 0) l.proposalRating(wp!.averageRating.toStringAsFixed(1), reviews) else l.publicProfileNew,
                            if ((wp?.experience ?? 0) > 0) l.proposalExperience(wp!.experience),
                          ].join(' · '),
                          style: t.bodySmall,
                        ),
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        // The group heading names the unit, so the row shows the amount only.
                        Text(formatRupees(p.proposedRate), style: SbTypography.numeric(t.titleSmall!), textAlign: TextAlign.end),
                        Text(p.estimatedDuration, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
                      ]),
                    ),
                  ]),
                ),
              );
            }),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/features/proposals/data/datasources/proposal_remote_datasource.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/features/proposals/presentation/widgets/proposal_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

enum MyProposalsTab { pending, accepted, notSelected, withdrawn }

MyProposalsTab myProposalsTabOf(ProposalStatus s) => switch (s) {
      ProposalStatus.pending => MyProposalsTab.pending,
      ProposalStatus.accepted => MyProposalsTab.accepted,
      ProposalStatus.rejected => MyProposalsTab.notSelected,
      ProposalStatus.withdrawn => MyProposalsTab.withdrawn,
    };

/// The signed-in worker's proposals, grouped by status.
class MyProposalsScreen extends ConsumerStatefulWidget {
  const MyProposalsScreen({super.key});

  @override
  ConsumerState<MyProposalsScreen> createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends ConsumerState<MyProposalsScreen> {
  MyProposalsTab _tab = MyProposalsTab.pending;

  // The first load opens on a tab that has something in it.
  bool _tabChosen = false;

  String _tabLabel(MyProposalsTab t, int n) {
    final l = context.l10n;
    final name = switch (t) {
      MyProposalsTab.pending => l.proposalStatusPending,
      MyProposalsTab.accepted => l.proposalStatusAccepted,
      MyProposalsTab.notSelected => l.proposalTabNotSelected,
      MyProposalsTab.withdrawn => l.proposalStatusWithdrawn,
    };
    return '$name · $n';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final edge = SbLayout.edge(context);
    final proposals = ref.watch(workerProposalsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.myProposalsTitle)),
      body: SbLoadSwitcher(
        loading: proposals.isLoading && !proposals.hasValue,
        child: proposals.when(
        loading: () => SbSkeletonList(item: const JobCardSkeleton(), count: 4, label: l.loading),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.myProposalsLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(workerProposalsStreamProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return SbStateView(
              kind: SbStateKind.empty,
              title: l.myProposalsEmptyTitle,
              message: l.myProposalsEmptyBody,
              actionLabel: l.myProposalsFindWork,
              onAction: () => context.go(RouteNames.workerJobFeedPath),
            );
          }
          final counts = {for (final t in MyProposalsTab.values) t: all.where((p) => myProposalsTabOf(p.status) == t).length};
          if (!_tabChosen) {
            _tabChosen = true;
            if (counts[_tab] == 0) _tab = MyProposalsTab.values.firstWhere((t) => counts[t]! > 0);
          }
          final shown = all.where((p) => myProposalsTabOf(p.status) == _tab).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workerProposalsStreamProvider),
            child: ListView(
              padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
              children: [
                SbReadableWidth(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final t in MyProposalsTab.values)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: SbSpace.s2),
                            child: ChoiceChip(
                              label: Text(_tabLabel(t, counts[t]!)),
                              selected: _tab == t,
                              onSelected: (_) => setState(() => _tab = t),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: SbSpace.s4),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: SbSpace.s8),
                        child: Text(l.myProposalsTabEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    for (final p in shown) ...[
                      MyProposalCard(proposal: p),
                      const SizedBox(height: SbSpace.s3),
                    ],
                  ]),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

/// One proposal in the worker's list: the job, the client's public name and
/// photo, the price, when it was sent, and where both the proposal and the job
/// stand now.
class MyProposalCard extends ConsumerStatefulWidget {
  const MyProposalCard({super.key, required this.proposal});
  final ProposalEntity proposal;

  @override
  ConsumerState<MyProposalCard> createState() => _MyProposalCardState();
}

class _MyProposalCardState extends ConsumerState<MyProposalCard> {
  bool _busy = false;

  ProposalEntity get p => widget.proposal;

  Future<void> _withdraw() async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: l.proposalWithdrawTitle,
      message: l.proposalWithdrawBody,
      confirmLabel: l.proposalWithdraw,
      cancelLabel: l.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    // The card leaves this tab once withdrawn, so keep the messenger to confirm.
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    void say(String text, {bool error = false}) => messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? scheme.error : scheme.primary,
        behavior: SnackBarBehavior.floating,
      ));
    setState(() => _busy = true);
    try {
      await ref.read(proposalRemoteDataSourceProvider).withdrawProposal(p.id);
      say(l.proposalWithdrawn);
    } catch (e) {
      say(proposalFailureOf(e) == ProposalFailure.network ? l.errNetwork : l.proposalActionFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final client = ref.watch(workerProfileProvider(p.clientId)).value;
    final jobAsync = ref.watch(jobByIdProvider(p.jobId));
    final job = jobAsync.hasError ? null : jobAsync.value;
    final clientName = (client?.formattedDisplayName ?? job?.clientName ?? '').trim();
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
            Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
              ProposalStatusBadge(proposal: p),
              // Once a job is no longer public only its owner and the hired
              // worker can read it; others see the status copied to the proposal.
              if (job != null || p.jobStatus != null) JobStatusBadge(status: p.jobStatusOr(job?.status)),
            ]),
            const SizedBox(height: SbSpace.s2),
            Text(p.jobTitle, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: SbSpace.s2),
            if (clientName.isNotEmpty)
              Row(children: [
                SbAvatar(name: clientName, imageUrl: client?.photoUrl ?? job?.clientPhotoUrl, size: 28),
                const SizedBox(width: SbSpace.s2),
                Expanded(
                  child: Text(
                    [clientName, if ((client?.city ?? job?.city ?? '').isNotEmpty) client?.city ?? job!.city].join(' · '),
                    style: t.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            const SizedBox(height: SbSpace.s2),
            Row(children: [
              Expanded(child: Text(proposalPriceLabel(l, p), style: SbTypography.numeric(t.titleSmall!))),
              Text(l.proposalSentOn(date.format(p.createdAt)), style: t.bodySmall),
            ]),
            if (p.closedBecauseFilled) ...[
              const SizedBox(height: SbSpace.s2),
              Text(l.proposalFilledNotice, style: t.bodySmall!.copyWith(color: c.textSecondary)),
            ],
            const Divider(height: SbSpace.s5),
            Wrap(spacing: SbSpace.s1, alignment: WrapAlignment.end, children: [
              if (p.status == ProposalStatus.pending)
                TextButton.icon(
                  icon: Icon(Icons.undo_rounded, size: 18, color: c.error),
                  label: Text(l.proposalWithdraw, style: TextStyle(color: c.error)),
                  onPressed: _busy ? null : _withdraw,
                ),
              if (job != null)
                TextButton(
                  onPressed: () => context.push(RouteNames.jobDetailsLocation(p.jobId), extra: job),
                  child: Text(l.proposalViewJob),
                ),
              TextButton(onPressed: open, child: Text(l.proposalView)),
            ]),
          ]),
        ),
      ),
    );
  }
}

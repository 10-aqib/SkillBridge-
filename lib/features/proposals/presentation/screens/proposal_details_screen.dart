import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/presentation/open_job_chat.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/features/proposals/data/datasources/proposal_remote_datasource.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/features/proposals/presentation/widgets/proposal_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// One proposal, for the worker who sent it or the client who received it.
class ProposalDetailsScreen extends ConsumerWidget {
  const ProposalDetailsScreen({super.key, required this.proposalId, this.initial});
  final String proposalId;
  final ProposalEntity? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final live = ref.watch(proposalByIdProvider(proposalId));
    final p = live.hasError ? null : (live.value ?? (live.isLoading ? initial : null));
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.proposalDetailsTitle)),
        body: live.isLoading && !live.hasError
            ? const Center(child: CircularProgressIndicator())
            : SbStateView(kind: SbStateKind.empty, title: l.proposalUnavailableTitle, message: l.proposalUnavailableBody),
      );
    }
    return _ProposalView(proposal: p);
  }
}

class _ProposalView extends ConsumerStatefulWidget {
  const _ProposalView({required this.proposal});
  final ProposalEntity proposal;

  @override
  ConsumerState<_ProposalView> createState() => _ProposalViewState();
}

class _ProposalViewState extends ConsumerState<_ProposalView> {
  bool _busy = false;
  bool _markedViewed = false;

  ProposalEntity get p => widget.proposal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeMarkViewed();
  }

  @override
  void didUpdateWidget(covariant _ProposalView old) {
    super.didUpdateWidget(old);
    _maybeMarkViewed();
  }

  /// The client opening a pending proposal tells the worker it was seen.
  void _maybeMarkViewed() {
    final me = ref.read(currentUserProvider);
    if (_markedViewed || me == null || me.uid != p.clientId) return;
    if (p.status != ProposalStatus.pending || p.wasViewed) return;
    _markedViewed = true;
    ref.read(proposalRemoteDataSourceProvider).markViewed(p.id).catchError((_) {});
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) context.showSnackBar(done);
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        switch (proposalFailureOf(e)) {
          ProposalFailure.jobUnavailable => l.proposalAcceptUnavailable,
          ProposalFailure.network => l.errNetwork,
          _ => l.proposalActionFailed,
        },
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
    if (ok && mounted) await _run(() => ref.read(proposalRemoteDataSourceProvider).withdrawProposal(p.id), l.proposalWithdrawn);
  }

  Future<void> _decline() async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: l.proposalDeclineTitle(p.workerName),
      message: l.proposalDeclineBody,
      confirmLabel: l.proposalDecline,
      cancelLabel: l.cancel,
      destructive: true,
    );
    if (ok && mounted) await _run(() => ref.read(proposalRemoteDataSourceProvider).rejectProposal(p.id), l.proposalDeclined);
  }

  Future<void> _accept(JobEntity job, UserEntity me) async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: l.proposalAcceptTitle(p.workerName),
      message: l.proposalAcceptBody,
      confirmLabel: l.proposalAccept,
      cancelLabel: l.cancel,
      details: Text(proposalPriceLabel(l, p), style: SbTypography.numeric(Theme.of(context).textTheme.titleMedium!)),
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref.read(proposalRemoteDataSourceProvider).acceptProposal(
            proposal: p,
            job: job,
            clientName: me.formattedDisplayName,
            clientPhotoUrl: me.photoUrl,
          ),
      l.proposalAccepted,
    );
  }

  Future<void> _chat(UserEntity me, JobEntity? job) async {
    final l = context.l10n;
    final isWorker = me.uid == p.workerId;
    final client = isWorker ? ref.read(workerProfileProvider(p.clientId)).value : null;
    final opened = await openJobChat(
      context,
      ref,
      me: me,
      otherUserId: isWorker ? p.clientId : p.workerId,
      otherUserName: isWorker ? (client?.formattedDisplayName ?? job?.clientName ?? '') : p.workerName,
      otherUserPhoto: isWorker ? (client?.photoUrl ?? job?.clientPhotoUrl) : p.workerPhotoUrl,
      jobId: p.jobId,
      jobTitle: p.jobTitle,
      workerId: p.workerId,
    );
    if (!opened && mounted) context.showSnackBar(l.jobMessageFailed, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    final me = ref.watch(currentUserProvider);
    final jobAsync = ref.watch(jobByIdProvider(p.jobId));
    final job = jobAsync.hasError ? null : jobAsync.value;
    final isWorker = me != null && me.uid == p.workerId;
    final isClient = me != null && me.uid == p.clientId;
    final active = me?.isActive ?? false;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());

    final canDecide = isClient && active && p.status == ProposalStatus.pending && (job?.isPublicOpen ?? false);
    final canWithdraw = isWorker && active && p.status == ProposalStatus.pending;
    final canResend = isWorker && active && p.status == ProposalStatus.withdrawn && (job?.isPublicOpen ?? false);
    final canChat = me != null && active && (isWorker || isClient) && p.status != ProposalStatus.withdrawn;

    final timeline = <String>[
      l.proposalSentOn(date.format(p.createdAt)),
      if (p.viewedAt != null) l.proposalViewedOn(date.format(p.viewedAt!)),
      if (p.decidedAt != null && p.status == ProposalStatus.accepted) l.proposalAcceptedOn(date.format(p.decidedAt!)),
      if (p.decidedAt != null && p.status == ProposalStatus.rejected) l.proposalClosedOn(date.format(p.decidedAt!)),
      if (p.withdrawnAt != null) l.proposalWithdrawnOn(date.format(p.withdrawnAt!)),
    ];

    Widget? bar;
    if (canDecide) {
      bar = Row(children: [
        Expanded(child: SbButton(label: l.proposalDecline, variant: SbButtonVariant.secondary, onPressed: _busy ? null : _decline)),
        const SizedBox(width: SbSpace.s3),
        Expanded(
          flex: 2,
          child: SbButton(label: l.proposalAccept, isLoading: _busy, onPressed: _busy ? null : () => _accept(job!, me)),
        ),
      ]);
    } else if (canWithdraw) {
      bar = Row(children: [
        Expanded(child: SbButton(label: l.proposalWithdraw, variant: SbButtonVariant.secondary, isLoading: _busy, onPressed: _busy ? null : _withdraw)),
        if (canChat) ...[
          const SizedBox(width: SbSpace.s3),
          Expanded(child: SbButton(label: l.jobMessageClient, icon: Icons.chat_bubble_outline_rounded, onPressed: () => _chat(me, job))),
        ],
      ]);
    } else if (canResend) {
      bar = SbButton(
        label: l.proposalSendAgain,
        expand: true,
        onPressed: () => context.push(RouteNames.jobProposeLocation(p.jobId), extra: job),
      );
    } else if ((isWorker || isClient) && p.status == ProposalStatus.accepted) {
      // The contract (id = proposal id) is where the work is started,
      // submitted and confirmed.
      bar = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbButton(
          label: l.contractOpen,
          icon: Icons.description_outlined,
          expand: true,
          onPressed: () => context.push(RouteNames.contractDetailsLocation(p.id)),
        ),
        if (canChat) ...[
          const SizedBox(height: SbSpace.s2),
          SbButton(
            label: isWorker ? l.jobMessageClient : l.proposalMessageWorker,
            icon: Icons.chat_bubble_outline_rounded,
            variant: SbButtonVariant.quiet,
            expand: true,
            onPressed: () => _chat(me, job),
          ),
        ],
      ]);
    }

    Widget card(List<Widget> children) => Container(
          padding: const EdgeInsets.all(SbSpace.s4),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(SbRadius.card), border: Border.all(color: c.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.proposalDetailsTitle)),
      bottomNavigationBar: bar == null
          ? null
          : SafeArea(
              child: Container(
                padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s3),
                decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
                child: bar,
              ),
            ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
        children: [
          SbReadableWidth(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                ProposalStatusBadge(proposal: p, dense: false),
                if (job != null || p.jobStatus != null) JobStatusBadge(status: p.jobStatusOr(job?.status), dense: false),
              ]),
              const SizedBox(height: SbSpace.s3),
              Text(p.jobTitle, style: t.headlineSmall),
              // Hidden when the job can no longer be read (filled by someone else).
              if (job != null)
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: AlignmentDirectional.centerStart),
                  onPressed: () => context.push(RouteNames.jobDetailsLocation(p.jobId), extra: job),
                  child: Text(l.proposalViewJob),
                )
              else
                const SizedBox(height: SbSpace.s2),
              if (isClient && p.status == ProposalStatus.pending && !(job?.isPublicOpen ?? true)) ...[
                SbInlineBanner(message: l.proposalJobNotOpenNotice, tone: SbTone.warning),
                const SizedBox(height: SbSpace.s3),
              ],
              if (isWorker && p.closedBecauseFilled) ...[
                SbInlineBanner(message: l.proposalFilledNotice, tone: SbTone.neutral),
                const SizedBox(height: SbSpace.s3),
              ],
              Container(
                padding: const EdgeInsets.all(SbSpace.s4),
                decoration: BoxDecoration(color: c.primarySubtle, borderRadius: BorderRadius.circular(SbRadius.card)),
                // Stacked so a long price ("Rs 12,500 · Fixed price") never runs into the time.
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.proposalPriceLabel, style: t.bodySmall!.copyWith(color: c.onPrimarySubtle)),
                  Text(proposalPriceLabel(l, p), style: SbTypography.numeric(t.titleMedium!).copyWith(color: c.onPrimarySubtle)),
                  const SizedBox(height: SbSpace.s3),
                  Text(l.proposalDurationLabel, style: t.bodySmall!.copyWith(color: c.onPrimarySubtle)),
                  Text(p.estimatedDuration, style: t.titleSmall!.copyWith(color: c.onPrimarySubtle)),
                ]),
              ),
              if (job != null && (isClient || isWorker)) ...[
                const SizedBox(height: SbSpace.s2),
                Text(isClient ? l.proposalYourBudget(jobBudgetLabel(l, job)) : l.proposalClientBudget(jobBudgetLabel(l, job)), style: t.bodySmall),
              ],
              const SizedBox(height: SbSpace.s5),
              Semantics(header: true, child: Text(l.proposalCoverLabel, style: t.titleMedium)),
              const SizedBox(height: SbSpace.s2),
              Text(p.coverLetter, style: t.bodyLarge),
              const SizedBox(height: SbSpace.s5),
              if (isClient) ...[
                Semantics(header: true, child: Text(l.proposalAboutWorker, style: t.titleMedium)),
                const SizedBox(height: SbSpace.s2),
                card([ProposalWorkerCard(proposal: p)]),
                const SizedBox(height: SbSpace.s5),
              ],
              Semantics(header: true, child: Text(l.proposalHistory, style: t.titleMedium)),
              const SizedBox(height: SbSpace.s2),
              for (final line in timeline)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: SbSpace.s1),
                  child: Row(children: [
                    Icon(Icons.circle, size: 8, color: c.textSecondary),
                    const SizedBox(width: SbSpace.s2),
                    Expanded(child: Text(line, style: t.bodyMedium)),
                  ]),
                ),
              if (p.status == ProposalStatus.accepted) ...[
                const SizedBox(height: SbSpace.s4),
                SbInlineBanner(message: l.proposalAcceptedNotice, tone: SbTone.success),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

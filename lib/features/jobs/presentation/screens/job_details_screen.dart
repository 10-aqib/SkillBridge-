import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/presentation/open_job_chat.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_actions.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_lifecycle_actions.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/features/proposals/presentation/widgets/proposal_ui.dart';
import 'package:skill_bridge/features/jobs/data/saved_jobs_repository.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Job details for clients and workers, kept live from Firestore.
///
/// Workers see public client details, can send (or review) a proposal, message
/// the client or report the job. Owners can edit, close or reopen, and review
/// received proposals. Existing hiring and work actions are in
/// [JobLifecycleActions].
class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobId, this.initial});

  final String jobId;

  /// Shown while the live copy loads (e.g. the card that was tapped).
  final JobEntity? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final live = ref.watch(jobByIdProvider(jobId));
    // Once the server refuses or fails, never keep showing an earlier copy
    // (e.g. a job cached on this device that this account may not read).
    final job = live.hasError ? null : (live.value ?? (live.isLoading ? initial : null));

    if (job == null) {
      return Scaffold(
        appBar: AppBar(),
        // An error wins over loading: Riverpod may be retrying in the background.
        body: live.isLoading && !live.hasError
            ? const SbDetailSkeleton()
            : live.hasError
                ? SbStateView(
                    kind: SbStateKind.error,
                    title: l.jobUnavailableTitle,
                    message: l.jobUnavailableBody,
                    actionLabel: l.tryAgain,
                    onAction: () => ref.invalidate(jobByIdProvider(jobId)),
                  )
                : SbStateView(kind: SbStateKind.empty, title: l.jobUnavailableTitle, message: l.jobUnavailableBody),
      );
    }
    return _JobDetailsView(job: job);
  }
}

class _JobDetailsView extends ConsumerStatefulWidget {
  const _JobDetailsView({required this.job});
  final JobEntity job;

  @override
  ConsumerState<_JobDetailsView> createState() => _JobDetailsViewState();
}

class _JobDetailsViewState extends ConsumerState<_JobDetailsView> {
  bool _openingChat = false;

  JobEntity get job => widget.job;

  Future<void> _messageClient(UserEntity me) async {
    final l = context.l10n;
    if (_openingChat) return;
    setState(() => _openingChat = true);
    final opened = await openJobChat(
      context,
      ref,
      me: me,
      otherUserId: job.clientId,
      otherUserName: job.clientName,
      otherUserPhoto: job.clientPhotoUrl,
      jobId: job.id,
      jobTitle: job.title,
      workerId: me.uid,
    );
    if (!mounted) return;
    setState(() => _openingChat = false);
    if (!opened) context.showSnackBar(l.jobMessageFailed, isError: true);
  }

  /// The worker's actions: send a proposal, see the one already sent, send it
  /// again after withdrawing, and message the client.
  Widget? _workerBar(UserEntity me, ProposalEntity? mine, bool loadingMine) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    final open = job.isPublicOpen;
    if (!open && mine == null) return null;

    final Widget? main;
    if (loadingMine) {
      main = null;
    } else if (mine == null) {
      main = SbButton(
        label: l.proposalSendCta,
        icon: Icons.send_rounded,
        expand: true,
        onPressed: () => context.push(RouteNames.jobProposeLocation(job.id), extra: job),
      );
    } else if (mine.status == ProposalStatus.withdrawn && open) {
      main = SbButton(
        label: l.proposalSendAgain,
        expand: true,
        onPressed: () => context.push(RouteNames.jobProposeLocation(job.id), extra: job),
      );
    } else {
      main = SbButton(
        label: l.proposalViewMine,
        variant: SbButtonVariant.secondary,
        expand: true,
        onPressed: () => context.push(RouteNames.proposalDetailsLocation(mine.id), extra: mine),
      );
    }
    // The rules allow a job chat while the job is open or once a proposal exists.
    // A worker who was not selected for a filled job is not offered a chat.
    final canChat = open || mine?.status == ProposalStatus.pending || mine?.status == ProposalStatus.accepted;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s3),
        decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (mine != null) ...[
            Row(children: [
              Text(l.proposalYourStatus, style: t.bodySmall),
              const SizedBox(width: SbSpace.s2),
              ProposalStatusBadge(proposal: mine),
            ]),
            const SizedBox(height: SbSpace.s2),
          ],
          // Stacked: both labels stay readable on a narrow phone.
          ?main,
          if (main != null && canChat) const SizedBox(height: SbSpace.s2),
          if (canChat)
            SbButton(
              label: l.jobMessageClient,
              icon: Icons.chat_bubble_outline_rounded,
              variant: main == null ? SbButtonVariant.secondary : SbButtonVariant.quiet,
              expand: true,
              isLoading: _openingChat,
              onPressed: () => _messageClient(me),
            ),
        ]),
      ),
    );
  }

  Future<void> _report(UserEntity me) async {
    final l = context.l10n;
    // Stored reason stays in English (admin review queue); labels localized.
    final reasons = {
      'Scam or fraud': l.jobReportScam,
      'Misleading job': l.jobReportMisleading,
      'Inappropriate content': l.jobReportInappropriate,
      'Other': l.reportReasonOther,
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(SbSpace.s5, SbSpace.s4, SbSpace.s5, SbSpace.s2),
            child: Text(l.jobReportTitle, style: Theme.of(sheet).textTheme.titleLarge),
          ),
          for (final e in reasons.entries) ListTile(title: Text(e.value), onTap: () => Navigator.pop(sheet, e.key)),
        ]),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await ref.read(firestoreProvider).collection('reports').add({
        'reporterId': me.uid,
        'targetUserId': job.clientId,
        'targetType': 'job',
        'targetId': job.id,
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) context.showSnackBar(l.reportSubmitted);
    } catch (_) {
      if (mounted) context.showSnackBar(l.reportFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    final me = ref.watch(currentUserProvider);
    final isOwner = me != null && me.uid == job.clientId;
    final isWorker = me != null && me.isWorker;
    final active = me?.isActive ?? false;
    final direct = job.selectedWorkerId != null && job.selectedWorkerId!.isNotEmpty;
    final mineAsync = isWorker && !isOwner ? ref.watch(myProposalForJobProvider(job.id)) : null;
    final mine = mineAsync?.value;
    final workerBar = isWorker && active && !isOwner ? _workerBar(me, mine, mineAsync?.isLoading ?? false) : null;
    final showLifecycle = direct || job.status != JobStatus.open || isOwner;

    Widget infoRow(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: SbSpace.s2),
          child: MergeSemantics(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 20, color: c.textSecondary),
              const SizedBox(width: SbSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: t.bodySmall),
                  const SizedBox(height: 2),
                  Text(value, style: t.bodyLarge),
                ]),
              ),
            ]),
          ),
        );

    Widget card(List<Widget> children) => Container(
          padding: const EdgeInsets.all(SbSpace.s4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(SbRadius.card),
            border: Border.all(color: c.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );

    final when = [
      urgencyLabel(l, job.urgency),
      if (job.startDate != null)
        l.jobPreferredOn(DateFormat.yMMMEd(Localizations.localeOf(context).toLanguageTag()).format(job.startDate!)),
    ].join(' · ');
    final area = jobAreaLabel(job);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.jobDetailsTitle),
        actions: [
          if (isOwner && job.status == JobStatus.open)
            IconButton(
              tooltip: l.jobEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(RouteNames.jobEditLocation(job.id), extra: job),
            ),
          if (isWorker && !isOwner) _SaveJobButton(job: job),
          if (!isOwner && me != null && job.isPublicOpen)
            IconButton(tooltip: l.jobReport, icon: const Icon(Icons.outlined_flag_rounded), onPressed: () => _report(me)),
        ],
      ),
      bottomNavigationBar: workerBar,
      body: ListView(
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
        children: [
          SbReadableWidth(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (me != null && !active) ...[
                SbInlineBanner(message: l.jobSuspendedNotice, tone: SbTone.warning),
                const SizedBox(height: SbSpace.s4),
              ],
              Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                JobStatusBadge(status: job.status, dense: false),
                if (isUrgentJob(job)) SbStatusBadge.urgent(label: l.jobUrgencyImmediate),
              ]),
              const SizedBox(height: SbSpace.s3),
              Text(job.title, style: t.headlineSmall),
              const SizedBox(height: SbSpace.s2),
              Row(children: [
                Icon(jobCategoryIcon(job.categoryId), size: 18, color: c.textSecondary),
                const SizedBox(width: SbSpace.s1),
                Flexible(
                  child: Text(
                    '${jobCategoryLabel(context, job.categoryId, job.categoryName)} · ${jobPostedLabel(context, job.createdAt)}',
                    style: t.bodyMedium!.copyWith(color: c.textSecondary),
                  ),
                ),
              ]),
              const SizedBox(height: SbSpace.s4),
              Container(
                padding: const EdgeInsets.all(SbSpace.s4),
                decoration: BoxDecoration(color: c.primarySubtle, borderRadius: BorderRadius.circular(SbRadius.card)),
                child: Row(children: [
                  Icon(Icons.payments_outlined, color: c.onPrimarySubtle),
                  const SizedBox(width: SbSpace.s3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.jobBudget, style: t.bodySmall!.copyWith(color: c.onPrimarySubtle)),
                      Text(jobBudgetLabel(l, job), style: SbTypography.numeric(t.titleMedium!).copyWith(color: c.onPrimarySubtle)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: SbSpace.s4),
              card([
                if (area.isNotEmpty) infoRow(Icons.place_outlined, l.jobFormSectionWhere, area),
                infoRow(Icons.schedule_rounded, l.jobFormSectionWhen, when),
                // A direct request names the worker it was sent to. A job filled
                // from proposals names the hired worker only to the two parties,
                // never to other applicants. (Direct requests cannot receive
                // proposals, so a proposal count means it was filled that way.)
                if (direct && job.totalProposals == 0)
                  infoRow(Icons.person_pin_outlined, l.jobDirectRequestLabel, job.selectedWorkerName ?? '')
                else if (direct && (isOwner || me?.uid == job.selectedWorkerId))
                  infoRow(Icons.how_to_reg_outlined, l.jobHiredLabel, job.selectedWorkerName ?? ''),
              ]),
              const SizedBox(height: SbSpace.s5),
              Semantics(header: true, child: Text(l.jobDescription, style: t.titleMedium)),
              const SizedBox(height: SbSpace.s2),
              Text(job.description, style: t.bodyLarge),
              if (job.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: SbSpace.s5),
                Semantics(header: true, child: Text(l.jobFormSkillsLabel, style: t.titleMedium)),
                const SizedBox(height: SbSpace.s2),
                Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                  for (final s in job.requiredSkills) Chip(label: Text(s)),
                ]),
              ],
              if (job.images.isNotEmpty) ...[
                const SizedBox(height: SbSpace.s5),
                Semantics(header: true, child: Text(l.jobFormSectionPhotos, style: t.titleMedium)),
                const SizedBox(height: SbSpace.s2),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: job.images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: SbSpace.s2),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(SbRadius.control),
                      child: CachedNetworkImage(imageUrl: job.images[i], width: 140, height: 110, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
              if (!isOwner) ...[
                const SizedBox(height: SbSpace.s5),
                _ClientCard(job: job),
              ],
              if (isOwner) ...[
                const SizedBox(height: SbSpace.s5),
                _OwnerPanel(job: job),
              ],
              if (showLifecycle && me != null) ...[
                const SizedBox(height: SbSpace.s4),
                JobLifecycleActions(job: job),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

/// Public details of the client who posted the job.
class _ClientCard extends ConsumerWidget {
  const _ClientCard({required this.job});
  final JobEntity job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final client = ref.watch(workerProfileProvider(job.clientId)).value;
    final name = (client?.formattedDisplayName ?? job.clientName).trim();
    final photo = client?.photoUrl ?? job.clientPhotoUrl;
    final since = client == null ? null : DateFormat.yMMM(Localizations.localeOf(context).toLanguageTag()).format(client.createdAt);
    return Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SbRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        SbAvatar(name: name.isEmpty ? '?' : name, imageUrl: photo, size: 48),
        const SizedBox(width: SbSpace.s3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.jobPostedBy, style: t.bodySmall),
            Text(name.isEmpty ? l.jobClientFallback : name, style: t.titleSmall),
            if (since != null || (client?.city ?? '').isNotEmpty)
              Text(
                [if (since != null) l.jobMemberSince(since), if ((client?.city ?? '').isNotEmpty) client!.city!].join(' · '),
                style: t.bodySmall,
              ),
          ]),
        ),
        if (client?.isEmailVerified == true) SbStatusBadge.verified(label: l.jobClientEmailVerified, dense: true),
      ]),
    );
  }
}

/// Owner tools: proposals received, edit, close or reopen.
class _OwnerPanel extends ConsumerWidget {
  const _OwnerPanel({required this.job});
  final JobEntity job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final direct = job.selectedWorkerId != null && job.selectedWorkerId!.isNotEmpty;
    final manageable = job.status == JobStatus.open || (job.status == JobStatus.cancelled && !direct);
    // Proposals stay reviewable after a hire (who was accepted, who was not).
    final showProposals = job.isPublicOpen || job.totalProposals > 0;
    if (!manageable && !showProposals) return const SizedBox.shrink();
    final proposalsButton = SbButton(
      label: l.proposalsViewReceived(job.totalProposals),
      icon: Icons.inbox_outlined,
      expand: true,
      variant: job.isPublicOpen && job.totalProposals > 0 ? SbButtonVariant.primary : SbButtonVariant.secondary,
      onPressed: () => context.push(RouteNames.jobProposalsLocation(job.id), extra: job),
    );
    if (!manageable) {
      return Container(
        padding: const EdgeInsets.all(SbSpace.s4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(SbRadius.card),
          border: Border.all(color: c.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.jobOwnerPanelTitle, style: t.titleSmall),
          const SizedBox(height: SbSpace.s3),
          proposalsButton,
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SbRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.jobOwnerPanelTitle, style: t.titleSmall),
        const SizedBox(height: SbSpace.s1),
        if (job.status == JobStatus.open && !direct) JobProposalCount(count: job.totalProposals, style: t.bodyMedium),
        if (job.status == JobStatus.cancelled) Text(l.jobClosedNotice, style: t.bodyMedium),
        const SizedBox(height: SbSpace.s3),
        if (showProposals) ...[proposalsButton, const SizedBox(height: SbSpace.s3)],
        Row(children: [
          if (job.status == JobStatus.open) ...[
            Expanded(
              child: SbButton(
                label: l.jobEdit,
                icon: Icons.edit_outlined,
                variant: SbButtonVariant.secondary,
                onPressed: () => context.push(RouteNames.jobEditLocation(job.id), extra: job),
              ),
            ),
            const SizedBox(width: SbSpace.s3),
            Expanded(
              child: SbButton(
                label: l.jobClose,
                variant: SbButtonVariant.quiet,
                onPressed: () => closeJobWithConfirm(context, ref, job),
              ),
            ),
          ] else
            Expanded(
              child: SbButton(
                label: l.jobReopen,
                icon: Icons.replay_rounded,
                variant: SbButtonVariant.secondary,
                onPressed: () => reopenJobWithConfirm(context, ref, job),
              ),
            ),
        ]),
      ]),
    );
  }
}

/// Bookmark a job to find it again under Saved jobs (Phase G6).
class _SaveJobButton extends ConsumerStatefulWidget {
  const _SaveJobButton({required this.job});
  final JobEntity job;

  @override
  ConsumerState<_SaveJobButton> createState() => _SaveJobButtonState();
}

class _SaveJobButtonState extends ConsumerState<_SaveJobButton> {
  /// What the button shows while a change is on its way to the server
  /// (optimistic UI): the tap shows its result at once, and it flips back
  /// with a message if the save fails.
  bool? _optimistic;
  bool _inFlight = false;

  Future<void> _toggle(bool saved) async {
    if (_inFlight) return;
    final l = context.l10n;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final target = !saved;
    HapticFeedback.selectionClick();
    setState(() {
      _optimistic = target;
      _inFlight = true;
    });
    context.showSnackBar(target ? l.jobBookmarkSaved : l.jobBookmarkRemoved);
    try {
      final store = ref.read(savedJobsStoreProvider);
      if (target) {
        await store.save(uid, widget.job);
      } else {
        await store.remove(uid, widget.job.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _optimistic = null);
        context.showSnackBar(l.errNetwork, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _inFlight = false;
          // The saved-jobs stream now carries the real state.
          if (_optimistic != null) _optimistic = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final saved = _optimistic ?? ref.watch(savedJobIdsProvider).contains(widget.job.id);
    return IconButton(
      tooltip: saved ? l.jobBookmarkRemove : l.jobBookmarkAdd,
      isSelected: saved,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey<bool>(saved),
        ),
      ),
      onPressed: () => _toggle(saved),
    );
  }
}

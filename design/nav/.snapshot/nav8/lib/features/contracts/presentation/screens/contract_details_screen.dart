import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/presentation/open_job_chat.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_remote_datasource.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/contract_ui.dart';
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/live_location_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// One contract for its two participants: terms, next step, private work
/// details, the other party, chat and a history built from stored records.
/// Every action runs through the trusted contract functions.
class ContractDetailsScreen extends ConsumerWidget {
  const ContractDetailsScreen({super.key, required this.contractId, this.initial});
  final String contractId;
  final ContractEntity? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final live = ref.watch(contractByIdProvider(contractId));
    final c = live.hasError ? null : (live.value ?? (live.isLoading ? initial : null));
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.contractDetailsTitle)),
        body: live.isLoading && !live.hasError
            ? const Center(child: CircularProgressIndicator())
            : SbStateView(kind: SbStateKind.empty, title: l.contractUnavailableTitle, message: l.contractUnavailableBody),
      );
    }
    return _ContractView(contract: c);
  }
}

class _ContractView extends ConsumerStatefulWidget {
  const _ContractView({required this.contract});
  final ContractEntity contract;

  @override
  ConsumerState<_ContractView> createState() => _ContractViewState();
}

class _ContractViewState extends ConsumerState<_ContractView> {
  bool _busy = false;
  bool _postingUpdate = false;
  bool _openingChat = false;

  ContractEntity get c => widget.contract;

  Future<void> _run(Future<void> Function() action, String done) async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) context.showSnackBar(done);
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        switch (contractFailureOf(e)) {
          ContractFailure.wrongState => l.contractActionChanged,
          ContractFailure.notAllowed => l.contractActionNotAllowed,
          ContractFailure.network => l.errNetwork,
          _ => l.contractActionFailed,
        },
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ContractActions get _actions => ref.read(contractActionsProvider);

  Future<void> _start() async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(context,
        title: l.contractStartTitle, message: l.contractStartBody, confirmLabel: l.contractStart, cancelLabel: l.cancel);
    if (ok && mounted) await _run(() => _actions.startWork(c.id), l.contractStarted);
  }

  Future<void> _confirm() async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(context,
        title: l.contractConfirmTitle, message: l.contractConfirmBody, confirmLabel: l.contractConfirm, cancelLabel: l.cancel);
    if (ok && mounted) await _run(() => _actions.confirmCompletion(c.id), l.contractConfirmed);
  }

  Future<void> _respond(bool accept) async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: accept ? l.contractRequestAcceptTitle : l.contractRequestDeclineTitle,
      message: accept ? l.contractRequestAcceptBody : l.contractRequestDeclineBody,
      confirmLabel: accept ? l.contractRequestAccept : l.contractRequestDecline,
      cancelLabel: l.cancel,
      destructive: !accept,
    );
    if (ok && mounted) {
      await _run(() => _actions.respondToRequest(c.id, accept: accept), accept ? l.contractRequestAccepted : l.contractRequestDeclined);
    }
  }

  Future<void> _requestChanges() async {
    final l = context.l10n;
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NoteSheet(
        title: l.contractRevisionTitle,
        body: l.contractRevisionBody(c.workerName, c.revisionsLeft),
        label: l.contractRevisionNoteLabel,
        hint: l.contractRevisionNoteHint,
        minLength: 10,
        tooShort: l.contractRevisionNoteTooShort,
        action: l.contractRevisionSend,
      ),
    );
    if (note != null && mounted) await _run(() => _actions.requestRevision(c.id, note: note), l.contractRevisionSent);
  }

  /// An update that may not have reached the server: retrying the same note
  /// reuses its id, so it is saved once; a different note gets a new id.
  ({String id, String note})? _pendingUpdate;

  Future<void> _postUpdate() async {
    final l = context.l10n;
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NoteSheet(
        title: l.contractUpdateSheetTitle,
        body: l.contractUpdateSheetBody(c.clientName),
        label: l.contractUpdateLabel,
        hint: l.contractUpdateHint,
        minLength: 2,
        tooShort: l.contractUpdateTooShort,
        action: l.contractUpdatePost,
      ),
    );
    if (note == null || !mounted) return;
    final pending = _pendingUpdate;
    final id = pending != null && pending.note == note ? pending.id : _actions.newRequestId();
    _pendingUpdate = (id: id, note: note);
    setState(() => _postingUpdate = true);
    try {
      await _actions.postProgressUpdate(c.id, requestId: id, note: note);
      _pendingUpdate = null;
      if (mounted) context.showSnackBar(l.contractUpdatePosted);
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        switch (contractFailureOf(e)) {
          ContractFailure.wrongState => l.contractActionChanged,
          ContractFailure.notAllowed => l.contractActionNotAllowed,
          ContractFailure.network => l.errNetwork,
          _ => l.contractActionFailed,
        },
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _postingUpdate = false);
    }
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CancelSheet(),
    );
    if (result != null && mounted) {
      await _run(() => _actions.cancel(c.id, reason: result.$1, note: result.$2), l.contractCancelled);
    }
  }

  Future<void> _shareAddress() async {
    final l = context.l10n;
    final address = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddressSheet(initial: c.serviceAddress ?? ''),
    );
    if (address != null && mounted) await _run(() => _actions.shareAddress(c.id, address), l.contractAddressShared);
  }

  Future<void> _chat(UserEntity me) async {
    final l = context.l10n;
    final isClient = me.uid == c.clientId;
    setState(() => _openingChat = true);
    final opened = await openJobChat(
      context,
      ref,
      me: me,
      otherUserId: isClient ? c.workerId : c.clientId,
      otherUserName: isClient ? c.workerName : c.clientName,
      otherUserPhoto: isClient ? c.workerPhotoUrl : c.clientPhotoUrl,
      jobId: c.jobId,
      jobTitle: c.jobTitle,
      workerId: c.workerId,
    );
    if (!mounted) return;
    setState(() => _openingChat = false);
    if (!opened) context.showSnackBar(l.jobMessageFailed, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final edge = SbLayout.edge(context);
    final me = ref.watch(currentUserProvider);
    final isClient = me != null && me.uid == c.clientId;
    final isWorker = me != null && me.uid == c.workerId;
    final active = me?.isActive ?? false;
    final stage = c.stage;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());

    // Sharing ends with the work: when the contract leaves the sharing
    // window, this device stops too (the server already removed it).
    ref.listen(contractByIdProvider(c.id), (_, next) {
      final now = next.value;
      if (now != null && !liveLocationOpen(now)) ref.read(liveLocationControllerProvider.notifier).contractClosed(now.id);
    });

    // The single next step for this person, shown as the primary action.
    Widget? primary;
    Widget? secondary;
    if (active && isWorker && stage == ContractStage.requested) {
      primary = SbButton(label: l.contractRequestAccept, expand: true, isLoading: _busy, onPressed: _busy ? null : () => _respond(true));
      secondary = SbButton(label: l.contractRequestDecline, variant: SbButtonVariant.secondary, expand: true, onPressed: _busy ? null : () => _respond(false));
    } else if (active && isWorker && stage == ContractStage.notStarted) {
      primary = SbButton(label: l.contractStart, icon: Icons.play_arrow_rounded, expand: true, isLoading: _busy, onPressed: _busy ? null : _start);
      secondary = SbButton(
          label: l.contractPostUpdate,
          icon: Icons.update_rounded,
          variant: SbButtonVariant.secondary,
          expand: true,
          isLoading: _postingUpdate,
          onPressed: _busy || _postingUpdate ? null : _postUpdate);
    } else if (active && isWorker && stage == ContractStage.inProgress) {
      primary = SbButton(
        label: c.awaitingResubmission ? l.contractResubmit : l.contractSubmit,
        icon: Icons.upload_rounded,
        expand: true,
        onPressed: () => context.push(RouteNames.contractSubmitLocation(c.id), extra: c),
      );
      secondary = SbButton(
          label: l.contractPostUpdate,
          icon: Icons.update_rounded,
          variant: SbButtonVariant.secondary,
          expand: true,
          isLoading: _postingUpdate,
          onPressed: _busy || _postingUpdate ? null : _postUpdate);
    } else if (active && isClient && stage == ContractStage.submitted) {
      primary = SbButton(label: l.contractConfirm, icon: Icons.check_rounded, expand: true, isLoading: _busy, onPressed: _busy ? null : _confirm);
      if (c.revisionsLeft > 0) {
        secondary = SbButton(label: l.contractRequestChanges, icon: Icons.replay_rounded, variant: SbButtonVariant.secondary, expand: true, onPressed: _busy ? null : _requestChanges);
      }
    } else if (stage == ContractStage.completed && ((isClient && !c.clientReviewed) || (isWorker && !c.workerReviewed))) {
      primary = SbButton(
        label: l.contractWriteReview,
        icon: Icons.star_outline_rounded,
        expand: true,
        onPressed: () => context.pushNamed(RouteNames.writeReviewName, pathParameters: {'contractId': c.id}, extra: c),
      );
    }

    final waiting = switch (stage) {
      ContractStage.requested => isClient ? l.contractNextClientRequested : null,
      ContractStage.notStarted => isClient ? l.contractNextClientNotStarted : null,
      ContractStage.inProgress when c.awaitingResubmission => isClient ? l.contractRevisionBannerClient(c.workerName) : null,
      ContractStage.inProgress => isClient ? l.contractNextClientInProgress : null,
      _ => null,
    };
    final submissions = ref.watch(contractSubmissionsProvider(c.id)).value ?? const [];
    final updates = ref.watch(contractUpdatesProvider(c.id)).value ?? const [];
    // Earlier rounds (the latest is shown as the submitted work).
    final earlier = submissions.where((s) => s.number < c.submissions).toList();
    final showSteps = stage != ContractStage.cancelled && stage != ContractStage.declined;
    final showUpdates = stage == ContractStage.notStarted || stage == ContractStage.inProgress || stage == ContractStage.submitted ||
        (stage == ContractStage.completed && updates.isNotEmpty);
    final open = stage == ContractStage.requested || stage == ContractStage.notStarted || stage == ContractStage.inProgress || stage == ContractStage.submitted;

    Widget card(List<Widget> children) => Container(
          padding: const EdgeInsets.all(SbSpace.s4),
          decoration: BoxDecoration(color: sb.surface, borderRadius: BorderRadius.circular(SbRadius.card), border: Border.all(color: sb.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );
    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: SbSpace.s5, bottom: SbSpace.s2),
          child: Semantics(header: true, child: Text(title, style: t.titleMedium)),
        );
    Widget info(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: SbSpace.s1),
          child: MergeSemantics(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 18, color: sb.textSecondary),
              const SizedBox(width: SbSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: t.bodySmall),
                  Text(value, style: t.bodyLarge),
                ]),
              ),
            ]),
          ),
        );

    final area = [if ((c.serviceArea ?? '').isNotEmpty) c.serviceArea!, if ((c.serviceCity ?? '').isNotEmpty) c.serviceCity!].join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(l.contractDetailsTitle)),
      bottomNavigationBar: primary == null && secondary == null
          ? null
          : SafeArea(
              child: Container(
                padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s3),
                decoration: BoxDecoration(color: sb.surface, border: Border(top: BorderSide(color: sb.border))),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ?primary,
                  if (primary != null && secondary != null) const SizedBox(height: SbSpace.s2),
                  ?secondary,
                ]),
              ),
            ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
        children: [
          SbReadableWidth(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                ContractStageBadge(stage: stage, dense: false),
                const SizedBox(width: SbSpace.s2),
                Expanded(
                  child: Text(l.contractCreatedOn(date.format(c.createdAt)),
                      style: t.bodySmall, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: SbSpace.s3),
              Text(c.jobTitle, style: t.headlineSmall),
              const SizedBox(height: SbSpace.s3),
              Container(
                padding: const EdgeInsets.all(SbSpace.s4),
                decoration: BoxDecoration(color: sb.primarySubtle, borderRadius: BorderRadius.circular(SbRadius.card)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.contractAgreedPrice, style: t.bodySmall!.copyWith(color: sb.onPrimarySubtle)),
                  Text(contractPriceLabel(l, c), style: SbTypography.numeric(t.titleMedium!).copyWith(color: sb.onPrimarySubtle)),
                  if (c.estimatedDuration.isNotEmpty) ...[
                    const SizedBox(height: SbSpace.s3),
                    Text(l.proposalDurationLabel, style: t.bodySmall!.copyWith(color: sb.onPrimarySubtle)),
                    Text(c.estimatedDuration, style: t.titleSmall!.copyWith(color: sb.onPrimarySubtle)),
                  ],
                ]),
              ),
              const SizedBox(height: SbSpace.s2),
              Text(l.contractPaymentNote, style: t.bodySmall),
              if (showSteps) ...[
                section(l.contractWhereThingsStand),
                ContractProgressSteps(contract: c),
              ],
              if (waiting != null) ...[
                const SizedBox(height: SbSpace.s4),
                SbInlineBanner(message: waiting, tone: SbTone.info),
              ],
              // Sent back: the worker sees exactly what to change.
              if (isWorker && c.awaitingResubmission) ...[
                const SizedBox(height: SbSpace.s4),
                SbInlineBanner(
                  message: l.contractRevisionBannerWorker(c.clientName, c.revisionNote ?? ''),
                  tone: SbTone.warning,
                  icon: Icons.replay_rounded,
                ),
              ],
              if (isWorker && stage == ContractStage.submitted && c.submittedAt != null) ...[
                const SizedBox(height: SbSpace.s4),
                SbInlineBanner(
                  message: l.contractWorkerSubmittedNotice(date.format(c.submittedAt!), c.clientName),
                  tone: SbTone.success,
                  icon: Icons.task_alt_rounded,
                ),
              ],
              if (stage == ContractStage.cancelled || stage == ContractStage.declined) ...[
                const SizedBox(height: SbSpace.s4),
                SbInlineBanner(
                  tone: SbTone.neutral,
                  message: stage == ContractStage.declined
                      ? l.contractDeclinedNotice
                      : l.contractCancelledNotice(
                          c.cancelledByRole == 'worker' ? l.contractRoleWorker : l.contractRoleClient,
                          contractCancelReasonLabel(l, c.cancelReason)),
                ),
              ],
              if (stage == ContractStage.completed) ...[
                const SizedBox(height: SbSpace.s4),
                SbInlineBanner(
                  icon: Icons.verified_rounded,
                  tone: SbTone.success,
                  message: c.completedAt == null
                      ? l.contractCompletedNotice
                      : isWorker
                          ? l.contractClientConfirmedNotice(c.clientName, date.format(c.completedAt!))
                          : l.contractClientCompletedNotice(date.format(c.completedAt!)),
                ),
              ],

              // Submitted work (both parties see what was handed in).
              if (c.submittedAt != null) ...[
                section(isClient && stage == ContractStage.submitted ? l.contractReviewWork : l.contractSubmittedWork),
                card([
                  if (c.submissions > 1) ...[
                    Text(l.contractSubmissionN(c.submissions), style: t.titleSmall),
                    const SizedBox(height: SbSpace.s1),
                  ],
                  Text(c.submissionNote ?? '', style: t.bodyLarge),
                  if (c.submissionAttachments.isNotEmpty) ...[
                    const SizedBox(height: SbSpace.s3),
                    ContractEvidenceStrip(paths: c.submissionAttachments),
                  ],
                  const SizedBox(height: SbSpace.s2),
                  Text(l.contractSubmittedOn(date.format(c.submittedAt!)), style: t.bodySmall),
                  if (isClient && stage == ContractStage.submitted) ...[
                    const SizedBox(height: SbSpace.s2),
                    Text(c.revisionsLeft > 0 ? l.contractRevisionsLeft(c.revisionsLeft) : l.contractNoRevisionsLeft(c.workerName), style: t.bodySmall),
                  ],
                ]),
                if (earlier.isNotEmpty) ...[
                  section(l.contractSubmissionHistory),
                  ContractSubmissionHistory(submissions: earlier.reversed.toList()),
                ],
              ],

              if (showUpdates) ...[
                section(l.contractUpdatesSection),
                card([
                  if (updates.isEmpty)
                    Text(isWorker ? l.contractUpdatesEmptyWorker : l.contractUpdatesEmptyClient(c.workerName), style: t.bodyMedium)
                  else
                    ContractUpdatesList(updates: updates),
                ]),
              ],

              section(l.contractWorkSection),
              card([
                if (c.jobDescription.isNotEmpty) ...[
                  Text(c.jobDescription, style: t.bodyLarge),
                  const SizedBox(height: SbSpace.s2),
                ],
                if (area.isNotEmpty) info(Icons.place_outlined, l.contractArea, area),
                // Exact address: on the private contract only (the public job
                // shows the general area). Shared by the client after hiring.
                if ((c.serviceAddress ?? '').isNotEmpty)
                  info(Icons.home_outlined, l.contractExactAddress, c.serviceAddress!)
                else if (isWorker && open)
                  info(Icons.home_outlined, l.contractExactAddress, l.contractAddressNotShared),
                if (isClient && open && active)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: Text((c.serviceAddress ?? '').isEmpty ? l.contractShareAddress : l.contractUpdateAddress),
                      onPressed: _busy ? null : _shareAddress,
                    ),
                  ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: AlignmentDirectional.centerStart),
                  onPressed: () => context.push(RouteNames.jobDetailsLocation(c.jobId)),
                  child: Text(l.proposalViewJob),
                ),
              ]),

              section(isClient ? l.contractYourWorker : l.contractYourClient),
              card([
                ContractPartyCard(
                  uid: isClient ? c.workerId : c.clientId,
                  fallbackName: isClient ? c.workerName : c.clientName,
                  fallbackPhoto: isClient ? c.workerPhotoUrl : c.clientPhotoUrl,
                  isWorker: isClient,
                ),
                if (me != null && active && stage != ContractStage.declined) ...[
                  const SizedBox(height: SbSpace.s3),
                  SbButton(
                    label: isClient ? l.proposalMessageWorker : l.jobMessageClient,
                    icon: Icons.chat_bubble_outline_rounded,
                    variant: SbButtonVariant.secondary,
                    expand: true,
                    isLoading: _openingChat,
                    onPressed: () => _chat(me),
                  ),
                ],
              ]),

              // Live location (Phase 4B): the worker shares on purpose; only
              // the client of this contract sees it, until the work is in.
              if (active && liveLocationOpen(c) && (isWorker || isClient)) ...[
                section(l.liveSectionTitle),
                card([isWorker ? WorkerLocationSharingPanel(contract: c) : ClientLiveLocationPanel(contract: c)]),
              ],

              section(l.contractHistory),
              ContractTimeline(contract: c, submissions: submissions, updates: updates),

              if (active && (isClient || isWorker) && c.canCancel) ...[
                const SizedBox(height: SbSpace.s2),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    icon: Icon(Icons.cancel_outlined, size: 18, color: sb.error),
                    label: Text(stage == ContractStage.requested && isClient ? l.contractWithdrawRequest : l.contractCancel,
                        style: TextStyle(color: sb.error)),
                    onPressed: _busy ? null : _cancel,
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

/// A short note with a minimum length (revision request, progress update);
/// returns the trimmed note, or null if dismissed.
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.title,
    required this.body,
    required this.label,
    required this.hint,
    required this.minLength,
    required this.tooShort,
    required this.action,
  });
  final String title;
  final String body;
  final String label;
  final String hint;
  final int minLength;
  final String tooShort;
  final String action;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final edge = SbLayout.edge(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(edge, 0, edge, MediaQuery.viewInsetsOf(context).bottom + SbSpace.s5),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(header: true, child: Text(widget.title, style: t.titleLarge)),
          const SizedBox(height: SbSpace.s2),
          Text(widget.body, style: t.bodyMedium),
          const SizedBox(height: SbSpace.s3),
          Form(
            key: _formKey,
            child: SbTextField(
              label: widget.label,
              hint: widget.hint,
              controller: _note,
              maxLength: 1000,
              maxLines: 4,
              validator: (v) => (v ?? '').trim().length < widget.minLength ? widget.tooShort : null,
            ),
          ),
          const SizedBox(height: SbSpace.s4),
          SbButton(
            label: widget.action,
            expand: true,
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) Navigator.pop(context, _note.text.trim());
            },
          ),
          const SizedBox(height: SbSpace.s2),
          SbButton(label: l.cancel, variant: SbButtonVariant.quiet, expand: true, onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

/// Reason (required) and an optional note; returns null if dismissed.
class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final edge = SbLayout.edge(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(edge, 0, edge, MediaQuery.viewInsetsOf(context).bottom + SbSpace.s5),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(header: true, child: Text(l.contractCancelTitle, style: t.titleLarge)),
          const SizedBox(height: SbSpace.s2),
          Text(l.contractCancelBody, style: t.bodyMedium),
          const SizedBox(height: SbSpace.s3),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(children: [
              for (final r in contractCancelReasons)
                RadioListTile<String>(
                  value: r,
                  contentPadding: EdgeInsets.zero,
                  title: Text(contractCancelReasonLabel(l, r)),
                ),
            ]),
          ),
          SbTextField(label: l.contractCancelNote, controller: _note, maxLength: 300, maxLines: 2),
          const SizedBox(height: SbSpace.s4),
          SbButton(
            label: l.contractCancel,
            variant: SbButtonVariant.destructive,
            expand: true,
            onPressed: _reason == null ? null : () => Navigator.pop(context, (_reason!, _note.text.trim())),
          ),
          const SizedBox(height: SbSpace.s2),
          SbButton(label: l.contractKeep, variant: SbButtonVariant.quiet, expand: true, onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({required this.initial});
  final String initial;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late final _address = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final edge = SbLayout.edge(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(edge, 0, edge, MediaQuery.viewInsetsOf(context).bottom + SbSpace.s5),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(header: true, child: Text(l.contractShareAddress, style: t.titleLarge)),
        const SizedBox(height: SbSpace.s2),
        Text(l.contractShareAddressBody, style: t.bodyMedium),
        const SizedBox(height: SbSpace.s3),
        Form(
          key: _formKey,
          child: SbTextField(
            label: l.contractExactAddress,
            controller: _address,
            maxLength: 200,
            maxLines: 2,
            validator: (v) => (v ?? '').trim().length < 5 ? l.contractAddressTooShort : null,
          ),
        ),
        const SizedBox(height: SbSpace.s4),
        SbButton(
          label: l.contractShareAddressAction,
          expand: true,
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) Navigator.pop(context, _address.text.trim());
          },
        ),
      ]),
    );
  }
}

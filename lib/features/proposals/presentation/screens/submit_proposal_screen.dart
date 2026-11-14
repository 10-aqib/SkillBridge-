import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/features/proposals/data/datasources/proposal_remote_datasource.dart';
import 'package:skill_bridge/features/proposals/data/models/proposal_model.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/features/proposals/presentation/widgets/proposal_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Worker sends (or re-sends) a proposal for an open job.
class SubmitProposalScreen extends ConsumerStatefulWidget {
  const SubmitProposalScreen({super.key, required this.jobId, this.initialJob});
  final String jobId;
  final JobEntity? initialJob;

  @override
  ConsumerState<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends ConsumerState<SubmitProposalScreen> {
  // Once the form is on screen it stays there: the local echo of the
  // proposal being sent must not swap it for "already sent" mid-send.
  _ProposalForm? _form;

  @override
  Widget build(BuildContext context) {
    if (_form != null) return _form!;
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final live = ref.watch(jobByIdProvider(widget.jobId));
    final job = live.hasError ? null : (live.value ?? (live.isLoading ? widget.initialJob : null));
    final mine = ref.watch(myProposalForJobProvider(widget.jobId));

    Widget blocked(String title, String body, {String? action, VoidCallback? onAction}) => Scaffold(
          appBar: AppBar(title: Text(l.proposalFormTitle)),
          body: SbStateView(kind: SbStateKind.empty, title: title, message: body, actionLabel: action, onAction: onAction),
        );

    if (job == null || mine.isLoading) {
      if (live.isLoading || mine.isLoading) {
        return Scaffold(appBar: AppBar(title: Text(l.proposalFormTitle)), body: const Center(child: CircularProgressIndicator()));
      }
      return blocked(l.jobUnavailableTitle, l.jobUnavailableBody);
    }
    if (me == null || !me.isWorker) return blocked(l.proposalOnlyWorkers, l.proposalOnlyWorkersBody);
    if (!me.isActive) return blocked(l.proposalSuspended, l.jobSuspendedNotice);
    if (job.clientId == me.uid) return blocked(l.proposalOwnJob, l.proposalOwnJobBody);

    final existing = mine.value;
    if (existing != null && existing.status != ProposalStatus.withdrawn) {
      return blocked(
        l.proposalAlreadySentTitle,
        l.proposalAlreadySentBody,
        action: l.proposalView,
        onAction: () => context.pushReplacement(RouteNames.proposalDetailsLocation(existing.id), extra: existing),
      );
    }
    if (!job.isPublicOpen) return blocked(l.proposalJobClosedTitle, l.proposalJobClosedBody);
    return _form = _ProposalForm(job: job, me: me, existing: existing);
  }
}

class _ProposalForm extends ConsumerStatefulWidget {
  const _ProposalForm({required this.job, required this.me, this.existing});
  final JobEntity job;
  final UserEntity me;
  final ProposalEntity? existing;

  static const int coverMin = 30;
  static const int coverMax = 2000;

  @override
  ConsumerState<_ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends ConsumerState<_ProposalForm> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  final _cover = TextEditingController();
  late String _rateType;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _rateType = e?.rateType ?? (['fixed', 'hourly', 'daily'].contains(widget.job.budgetType) ? widget.job.budgetType : 'fixed');
    if (e != null) {
      _price.text = e.proposedRate.round().toString();
      _duration.text = e.estimatedDuration;
      _cover.text = e.coverLetter;
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _duration.dispose();
    _cover.dispose();
    super.dispose();
  }

  ProposalModel _proposal() => ProposalModel(
        id: ProposalEntity.idFor(widget.job.id, widget.me.uid),
        jobId: widget.job.id,
        jobTitle: widget.job.title,
        workerId: widget.me.uid,
        workerName: widget.me.formattedDisplayName,
        workerPhotoUrl: widget.me.photoUrl,
        clientId: widget.job.clientId,
        coverLetter: _cover.text.trim(),
        proposedRate: double.parse(_price.text.trim()),
        rateType: _rateType,
        estimatedDuration: _duration.text.trim(),
        status: ProposalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  Future<void> _submit() async {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    if (_sending || _sent) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      context.showSnackBar(l.jobFormFixErrors, isError: true);
      return;
    }
    final p = _proposal();
    final ok = await showSbConfirmSheet(
      context,
      title: l.proposalConfirmTitle,
      message: l.proposalConfirmBody,
      confirmLabel: widget.existing != null ? l.proposalSendAgain : l.proposalSend,
      cancelLabel: l.jobConfirmKeepEditing,
      details: _Summary(proposal: p, job: widget.job),
    );
    if (!ok || !mounted) return;
    setState(() => _sending = true);
    try {
      final id = await ref.read(proposalRemoteDataSourceProvider).submitProposal(p, existing: widget.existing);
      if (!mounted) return;
      setState(() => _sent = true);
      context.showSnackBar(l.proposalSent);
      context.pushReplacement(RouteNames.proposalDetailsLocation(id));
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        switch (proposalFailureOf(e)) {
          ProposalFailure.alreadySent => l.proposalAlreadySentTitle,
          ProposalFailure.jobUnavailable => l.proposalJobClosedBody,
          ProposalFailure.network => l.errNetwork,
          _ => l.proposalSendFailed,
        },
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    final job = widget.job;
    final durations = [l.proposalDurationSameDay, l.proposalDuration1to2, l.proposalDuration3to5, l.proposalDurationWeek, l.proposalDuration2Weeks];

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? l.proposalFormTitleAgain : l.proposalFormTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s3),
          child: SbButton(
            label: l.proposalReview,
            expand: true,
            isLoading: _sending,
            onPressed: _sending || _sent ? null : _submit,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
          children: [
            SbReadableWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.all(SbSpace.s4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(SbRadius.card),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(jobCategoryLabel(context, job.categoryId, job.categoryName), style: t.labelMedium!.copyWith(color: c.textSecondary)),
                    Text(job.title, style: t.titleMedium),
                    const SizedBox(height: SbSpace.s2),
                    Text(l.proposalClientBudget(jobBudgetLabel(l, job)), style: t.bodyMedium),
                    if (jobAreaLabel(job).isNotEmpty) Text(jobAreaLabel(job), style: t.bodySmall),
                  ]),
                ),
                if (widget.existing != null) ...[
                  const SizedBox(height: SbSpace.s4),
                  SbInlineBanner(message: l.proposalResendNote, tone: SbTone.info),
                ],
                const SizedBox(height: SbSpace.s5),
                Text(l.jobFormRequiredNote, style: t.bodySmall),
                const SizedBox(height: SbSpace.s4),
                Semantics(header: true, child: Text(l.proposalPriceSection, style: t.titleMedium)),
                const SizedBox(height: SbSpace.s3),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'fixed', label: Text(l.jobBudgetTypeFixed)),
                    ButtonSegment(value: 'hourly', label: Text(l.jobBudgetTypeHourly)),
                    ButtonSegment(value: 'daily', label: Text(l.jobBudgetTypeDaily)),
                  ],
                  selected: {_rateType},
                  showSelectedIcon: false,
                  onSelectionChanged: _sending ? null : (s) => setState(() => _rateType = s.first),
                ),
                const SizedBox(height: SbSpace.s3),
                SbTextField(
                  label: l.proposalPriceLabel,
                  requiredMarker: '*',
                  controller: _price,
                  prefixText: 'Rs ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return l.jobFormBudgetRequired;
                    if (n > 10000000) return l.jobFormBudgetTooHigh;
                    return null;
                  },
                ),
                const SizedBox(height: SbSpace.s5),
                Semantics(header: true, child: Text(l.proposalDurationLabel, style: t.titleMedium)),
                const SizedBox(height: SbSpace.s2),
                Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                  for (final d in durations)
                    ChoiceChip(
                      label: Text(d),
                      selected: _duration.text == d,
                      onSelected: _sending ? null : (_) => setState(() => _duration.text = d),
                    ),
                ]),
                const SizedBox(height: SbSpace.s3),
                SbTextField(
                  label: l.proposalDurationField,
                  hint: l.proposalDurationHint,
                  requiredMarker: '*',
                  controller: _duration,
                  maxLength: 60,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v ?? '').trim().length < 2 ? l.proposalDurationRequired : null,
                ),
                const SizedBox(height: SbSpace.s4),
                SbTextField(
                  label: l.proposalCoverLabel,
                  hint: l.proposalCoverHint,
                  requiredMarker: '*',
                  controller: _cover,
                  maxLines: 7,
                  maxLength: _ProposalForm.coverMax,
                  keyboardType: TextInputType.multiline,
                  validator: (v) => (v ?? '').trim().length < _ProposalForm.coverMin ? l.proposalCoverRequired : null,
                ),
                const SizedBox(height: SbSpace.s3),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.badge_outlined, size: 18, color: c.textSecondary),
                  const SizedBox(width: SbSpace.s2),
                  Expanded(child: Text(l.proposalProfileNote, style: t.bodySmall)),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.proposal, required this.job});
  final ProposalModel proposal;
  final JobEntity job;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    return Container(
      padding: const EdgeInsets.all(SbSpace.s3),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(SbRadius.control)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(job.title, style: t.titleSmall),
        const SizedBox(height: SbSpace.s2),
        Text(proposalPriceLabel(l, proposal), style: SbTypography.numeric(t.titleMedium!)),
        Text(proposal.estimatedDuration, style: t.bodyMedium),
        const SizedBox(height: SbSpace.s2),
        Text(proposal.coverLetter, style: t.bodySmall, maxLines: 4, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

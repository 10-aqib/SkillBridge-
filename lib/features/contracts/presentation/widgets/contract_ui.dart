import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_activity.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// "Rs 2,500 · Fixed price", "Rs 800 / hour", "Rs 4,500 / day".
String contractPriceLabel(AppLocalizations l, ContractEntity c) {
  final min = c.priceMin;
  final amount = min != null && min < c.agreedRate
      ? '${formatRupees(min)} – ${formatRupees(c.agreedRate).replaceFirst('Rs ', '')}'
      : formatRupees(c.agreedRate);
  return switch (c.rateType) {
    'hourly' => l.jobBudgetPerHour(amount),
    'daily' => l.jobBudgetPerDay(amount),
    _ => l.jobBudgetFixedPrice(amount),
  };
}

String contractStageLabel(AppLocalizations l, ContractStage s) => switch (s) {
      ContractStage.requested => l.contractStageRequested,
      ContractStage.notStarted => l.contractStageNotStarted,
      ContractStage.inProgress => l.contractStageInProgress,
      ContractStage.submitted => l.contractStageSubmitted,
      ContractStage.completed => l.contractStageCompleted,
      ContractStage.cancelled => l.contractStageCancelled,
      ContractStage.declined => l.contractStageDeclined,
    };

String contractCancelReasonLabel(AppLocalizations l, String? code) => switch (code) {
      'schedule_conflict' => l.contractCancelReasonSchedule,
      'no_longer_needed' => l.contractCancelReasonNotNeeded,
      'agreed_with_other_party' => l.contractCancelReasonAgreed,
      'safety_concern' => l.contractCancelReasonSafety,
      _ => l.contractCancelReasonOther,
    };

class ContractStageBadge extends StatelessWidget {
  const ContractStageBadge({super.key, required this.stage, this.dense = true});
  final ContractStage stage;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (icon, tone) = switch (stage) {
      ContractStage.requested => (Icons.mark_email_unread_outlined, SbTone.warning),
      ContractStage.notStarted => (Icons.schedule_rounded, SbTone.info),
      ContractStage.inProgress => (Icons.construction_rounded, SbTone.accent),
      ContractStage.submitted => (Icons.fact_check_outlined, SbTone.warning),
      ContractStage.completed => (Icons.check_circle_outline_rounded, SbTone.success),
      ContractStage.cancelled => (Icons.cancel_outlined, SbTone.neutral),
      ContractStage.declined => (Icons.do_not_disturb_on_outlined, SbTone.neutral),
    };
    return SbStatusBadge(label: contractStageLabel(l, stage), icon: icon, tone: tone, dense: dense);
  }
}

/// The other participant, from their public profile only (no phone, email or
/// address). Workers show headline, skills and work photos; clients show
/// city and member-since.
class ContractPartyCard extends ConsumerWidget {
  const ContractPartyCard({
    super.key,
    required this.uid,
    required this.fallbackName,
    this.fallbackPhoto,
    required this.isWorker,
    this.showDetails = true,
  });
  final String uid;
  final String fallbackName;
  final String? fallbackPhoto;
  final bool isWorker;
  final bool showDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final person = ref.watch(workerProfileProvider(uid)).value;
    final wp = person?.workerProfile;
    final name = (person?.formattedDisplayName ?? fallbackName).trim();
    final reviews = wp?.totalReviews ?? 0;
    final since = person == null ? null : DateFormat.yMMM(Localizations.localeOf(context).toLanguageTag()).format(person.createdAt);
    final lines = <String>[
      if (isWorker && reviews > 0) l.proposalRating(wp!.averageRating.toStringAsFixed(1), reviews) else if (isWorker) l.publicProfileNew,
      if (isWorker && (wp?.experience ?? 0) > 0) l.proposalExperience(wp!.experience),
      if ((person?.city ?? '').isNotEmpty) person!.city!,
      if (!isWorker && since != null) l.jobMemberSince(since),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        SbAvatar(name: name.isEmpty ? '?' : name, imageUrl: person?.photoUrl ?? fallbackPhoto, size: showDetails ? 52 : 40),
        const SizedBox(width: SbSpace.s3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (wp?.isVerified == true) ...[
                const SizedBox(width: SbSpace.s1),
                Icon(Icons.verified_rounded, size: 18, color: c.success, semanticLabel: l.verificationBadge),
              ],
            ]),
            if (isWorker && (wp?.headline ?? '').isNotEmpty) Text(wp!.headline, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (lines.isNotEmpty) Text(lines.join(' · '), style: t.bodySmall),
          ]),
        ),
      ]),
      if (showDetails && isWorker && (wp?.skills.isNotEmpty ?? false)) ...[
        const SizedBox(height: SbSpace.s3),
        Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
          for (final s in wp!.skills.take(6)) Chip(label: Text(s), visualDensity: VisualDensity.compact),
        ]),
      ],
      if (showDetails && isWorker && (wp?.portfolioImages.isNotEmpty ?? false)) ...[
        const SizedBox(height: SbSpace.s3),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wp!.portfolioImages.length.clamp(0, 6),
            separatorBuilder: (_, _) => const SizedBox(width: SbSpace.s2),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(SbRadius.control),
              child: CachedNetworkImage(imageUrl: wp.portfolioImages[i], width: 86, height: 64, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
      if (showDetails && isWorker)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.person_outline_rounded, size: 18),
            label: Text(l.proposalViewProfile),
            onPressed: () => context.pushNamed(RouteNames.publicWorkerProfileName, pathParameters: {'workerId': uid}),
          ),
        ),
    ]);
  }
}

/// One real event in the contract's history.
class ContractEvent {
  const ContractEvent(this.at, this.label, this.icon, {this.detail});
  final DateTime at;
  final String label;
  final IconData icon;
  final String? detail;
}

/// History from stored records only; nothing is invented. Older contracts
/// without lifecycle timestamps simply show fewer events. With the
/// submission history and progress updates (Phase 4B) every round is shown;
/// without them, the contract's own latest submission and revision.
List<ContractEvent> contractEvents(
  AppLocalizations l,
  ContractEntity c, {
  List<ContractSubmission> submissions = const [],
  List<ContractUpdate> updates = const [],
}) {
  final history = submissions.where((s) => s.submittedAt != null).toList();
  final events = <ContractEvent>[
    if (c.isDirectBooking)
      ContractEvent(c.createdAt, l.contractEventRequested, Icons.mark_email_unread_outlined)
    else if (c.isDirectRequest) ...[
      if (c.acceptedAt != null) ContractEvent(c.acceptedAt!, l.contractEventDirectAccepted, Icons.how_to_reg_outlined),
      ContractEvent(c.createdAt, l.contractEventCreated, Icons.description_outlined),
    ] else ...[
      if (c.acceptedAt != null) ContractEvent(c.acceptedAt!, l.contractEventProposalAccepted, Icons.how_to_reg_outlined),
      ContractEvent(c.createdAt, l.contractEventCreated, Icons.description_outlined),
    ],
    if (c.isDirectBooking && c.respondedAt != null)
      ContractEvent(c.respondedAt!, c.status.name == 'rejected' ? l.contractEventRequestDeclined : l.contractEventRequestAccepted,
          c.status.name == 'rejected' ? Icons.do_not_disturb_on_outlined : Icons.how_to_reg_outlined),
    if (c.addressSharedAt != null) ContractEvent(c.addressSharedAt!, l.contractEventAddressShared, Icons.home_outlined),
    if (c.workStartedAt != null) ContractEvent(c.workStartedAt!, l.contractEventStarted, Icons.construction_rounded),
    if (history.isEmpty) ...[
      if (c.submittedAt != null)
        ContractEvent(c.submittedAt!, c.submissions > 1 ? l.contractEventResubmitted(c.submissions) : l.contractEventSubmitted, Icons.fact_check_outlined),
      if (c.revisionRequestedAt != null)
        ContractEvent(c.revisionRequestedAt!, l.contractEventRevision, Icons.replay_rounded, detail: c.revisionNote),
    ] else
      for (final s in history) ...[
        ContractEvent(s.submittedAt!, s.number > 1 ? l.contractEventResubmitted(s.number) : l.contractEventSubmitted, Icons.fact_check_outlined),
        if (s.revisionRequestedAt != null)
          ContractEvent(s.revisionRequestedAt!, l.contractEventRevision, Icons.replay_rounded, detail: s.revisionNote),
      ],
    for (final u in updates) ContractEvent(u.createdAt, l.contractEventUpdate, Icons.update_rounded, detail: u.note),
    if (c.completedAt != null) ContractEvent(c.completedAt!, l.contractEventCompleted, Icons.check_circle_outline_rounded),
    if (c.cancelledAt != null)
      ContractEvent(
        c.cancelledAt!,
        c.cancelledByRole == 'worker' ? l.contractEventCancelledByWorker : l.contractEventCancelledByClient,
        Icons.cancel_outlined,
        detail: [contractCancelReasonLabel(l, c.cancelReason), if ((c.cancelNote ?? '').isNotEmpty) c.cancelNote!].join(' · '),
      ),
  ];
  events.sort((a, b) => a.at.compareTo(b.at));
  return events;
}

class ContractTimeline extends StatelessWidget {
  const ContractTimeline({super.key, required this.contract, this.submissions = const [], this.updates = const []});
  final ContractEntity contract;
  final List<ContractSubmission> submissions;
  final List<ContractUpdate> updates;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_jm();
    final events = contractEvents(l, contract, submissions: submissions, updates: updates);
    return Column(children: [
      for (var i = 0; i < events.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 28,
              child: Column(children: [
                Icon(events[i].icon, size: 18, color: i == events.length - 1 ? c.primary : c.textSecondary),
                if (i < events.length - 1) Expanded(child: Container(width: 1.5, color: c.border)),
              ]),
            ),
            const SizedBox(width: SbSpace.s2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: SbSpace.s4),
                child: MergeSemantics(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(events[i].label, style: t.bodyMedium),
                    Text(fmt.format(events[i].at), style: t.bodySmall),
                    if ((events[i].detail ?? '').isNotEmpty) Text(events[i].detail!, style: t.bodySmall),
                  ]),
                ),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// Where the work stands: hired → started → submitted → confirmed, with the
/// current step marked. Shown for open and completed contracts.
class ContractProgressSteps extends StatelessWidget {
  const ContractProgressSteps({super.key, required this.contract});
  final ContractEntity contract;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final labels = [l.contractStepHired, l.contractStepStarted, l.contractStepSubmitted, l.contractStepConfirmed];
    // Steps done so far.
    final done = switch (contract.stage) {
      ContractStage.requested => 0,
      ContractStage.notStarted => 1,
      ContractStage.inProgress => 2,
      ContractStage.submitted => 3,
      ContractStage.completed => 4,
      _ => 0,
    };
    final current = done.clamp(0, labels.length - 1);
    return Semantics(
      label: '${l.contractWhereThingsStand}: ${l.contractStepsLabel(done, labels.length)}, ${[for (var i = 0; i < done; i++) labels[i]].join(', ')}',
      excludeSemantics: true,
      child: Row(children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(children: [
              Row(children: [
                Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : (i <= done - 1 ? sb.primary : sb.border))),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < done ? sb.primary : sb.surface,
                    border: Border.all(color: i < done || i == current ? sb.primary : sb.border, width: 2),
                  ),
                  child: i < done ? Icon(Icons.check_rounded, size: 14, color: sb.onPrimary) : null,
                ),
                Expanded(child: Container(height: 2, color: i == labels.length - 1 ? Colors.transparent : (i < done - 1 ? sb.primary : sb.border))),
              ]),
              const SizedBox(height: SbSpace.s1),
              Text(labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: t.labelSmall!.copyWith(
                    color: i < done || i == current ? sb.text : sb.textSecondary,
                    fontWeight: i == current && done < labels.length ? FontWeight.w700 : null,
                  )),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// Evidence photos, read with getData() under the party's own access (no
/// shareable links). Tap to enlarge.
class ContractEvidenceStrip extends ConsumerWidget {
  const ContractEvidenceStrip({super.key, required this.paths});
  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sb = context.sb;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const SizedBox(width: SbSpace.s2),
        itemBuilder: (context, i) {
          final bytes = ref.watch(contractEvidenceProvider(paths[i]));
          return ClipRRect(
            borderRadius: BorderRadius.circular(SbRadius.control),
            child: Container(
              width: 128,
              color: sb.surfaceSunken,
              child: bytes.when(
                loading: () => const SbSkeleton(height: double.infinity, radius: 0),
                error: (_, _) => Center(child: Icon(Icons.broken_image_outlined, color: sb.textSecondary, semanticLabel: l.contractEvidenceUnavailable)),
                data: (b) => b == null
                    ? Center(child: Icon(Icons.broken_image_outlined, color: sb.textSecondary, semanticLabel: l.contractEvidenceUnavailable))
                    : Semantics(
                        button: true,
                        image: true,
                        label: l.contractEvidencePhoto(i + 1),
                        child: InkWell(
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (ctx) => Dialog(
                              clipBehavior: Clip.antiAlias,
                              child: Stack(children: [
                                InteractiveViewer(child: Image.memory(b, fit: BoxFit.contain)),
                                PositionedDirectional(
                                  top: SbSpace.s2,
                                  end: SbSpace.s2,
                                  child: IconButton.filledTonal(
                                    tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          child: Image.memory(b, fit: BoxFit.cover),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Earlier rounds of the work (each submission and the changes asked for).
class ContractSubmissionHistory extends StatelessWidget {
  const ContractSubmissionHistory({super.key, required this.submissions});
  final List<ContractSubmission> submissions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_jm();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final s in submissions)
        Container(
          margin: const EdgeInsets.only(bottom: SbSpace.s2),
          padding: const EdgeInsets.all(SbSpace.s3),
          decoration: BoxDecoration(color: sb.surface, borderRadius: BorderRadius.circular(SbRadius.card), border: Border.all(color: sb.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.contractSubmissionN(s.number), style: t.titleSmall),
            if (s.submittedAt != null) Text(fmt.format(s.submittedAt!), style: t.bodySmall),
            if (s.note.isNotEmpty) ...[const SizedBox(height: SbSpace.s1), Text(s.note, style: t.bodyMedium)],
            if (s.attachments.isNotEmpty) ...[const SizedBox(height: SbSpace.s2), ContractEvidenceStrip(paths: s.attachments)],
            if (s.sentBack) ...[
              const SizedBox(height: SbSpace.s2),
              SbInlineBanner(message: l.contractSubmissionChangesRequested(s.revisionNote!), tone: SbTone.warning, icon: Icons.replay_rounded),
            ],
          ]),
        ),
    ]);
  }
}

/// The worker's progress updates, newest first.
class ContractUpdatesList extends StatelessWidget {
  const ContractUpdatesList({super.key, required this.updates});
  final List<ContractUpdate> updates;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_jm();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final u in updates)
        Padding(
          padding: const EdgeInsets.only(bottom: SbSpace.s3),
          child: MergeSemantics(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.update_rounded, size: 18, color: sb.primary),
              const SizedBox(width: SbSpace.s2),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.note, style: t.bodyMedium),
                  Text(fmt.format(u.createdAt), style: t.bodySmall),
                ]),
              ),
            ]),
          ),
        ),
    ]);
  }
}

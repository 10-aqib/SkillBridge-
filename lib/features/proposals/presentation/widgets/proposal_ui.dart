import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// "Rs 2,500 · Fixed price", "Rs 800 / hour", "Rs 4,500 / day".
String proposalPriceLabel(AppLocalizations l, ProposalEntity p) {
  final amount = formatRupees(p.proposedRate);
  return switch (p.rateType) {
    'hourly' => l.jobBudgetPerHour(amount),
    'daily' => l.jobBudgetPerDay(amount),
    _ => l.jobBudgetFixedPrice(amount),
  };
}

/// Status as the person looking at it should understand it.
class ProposalStatusBadge extends StatelessWidget {
  const ProposalStatusBadge({super.key, required this.proposal, this.dense = true});
  final ProposalEntity proposal;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = proposal;
    final (label, icon, tone) = switch (p.status) {
      ProposalStatus.pending when p.wasViewed => (l.proposalStatusViewed, Icons.visibility_outlined, SbTone.info),
      ProposalStatus.pending => (l.proposalStatusPending, Icons.schedule_rounded, SbTone.warning),
      ProposalStatus.accepted => (l.proposalStatusAccepted, Icons.check_circle_outline_rounded, SbTone.success),
      ProposalStatus.rejected when p.closedBecauseFilled => (l.proposalStatusFilled, Icons.do_not_disturb_on_outlined, SbTone.neutral),
      ProposalStatus.rejected => (l.proposalStatusDeclined, Icons.cancel_outlined, SbTone.neutral),
      ProposalStatus.withdrawn => (l.proposalStatusWithdrawn, Icons.undo_rounded, SbTone.neutral),
    };
    return SbStatusBadge(label: label, icon: icon, tone: tone, dense: dense);
  }
}

/// The worker as the client sees them, from their real profile: photo, name,
/// headline, skills, experience, work photos, and a rating only when reviews
/// exist. Nothing here is invented.
class ProposalWorkerCard extends ConsumerWidget {
  const ProposalWorkerCard({super.key, required this.proposal, this.compact = false});
  final ProposalEntity proposal;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final worker = ref.watch(workerProfileProvider(proposal.workerId)).value;
    final wp = worker?.workerProfile;
    final name = (worker?.formattedDisplayName ?? proposal.workerName).trim();
    final photo = worker?.photoUrl ?? proposal.workerPhotoUrl;
    final reviews = wp?.totalReviews ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        SbAvatar(name: name.isEmpty ? '?' : name, imageUrl: photo, size: compact ? 44 : 56),
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
            if ((wp?.headline ?? '').isNotEmpty)
              Text(wp!.headline, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              [
                if (reviews > 0) l.proposalRating(wp!.averageRating.toStringAsFixed(1), reviews) else l.publicProfileNew,
                if ((wp?.experience ?? 0) > 0) l.proposalExperience(wp!.experience),
                if ((wp?.city ?? '').isNotEmpty) wp!.city,
              ].join(' · '),
              style: t.bodySmall,
            ),
          ]),
        ),
      ]),
      if (!compact && (wp?.skills.isNotEmpty ?? false)) ...[
        const SizedBox(height: SbSpace.s3),
        Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
          for (final s in wp!.skills.take(6)) Chip(label: Text(s), visualDensity: VisualDensity.compact),
        ]),
      ],
      if (!compact && (wp?.portfolioImages.isNotEmpty ?? false)) ...[
        const SizedBox(height: SbSpace.s3),
        Text(l.publicProfileWorkTab, style: t.labelLarge),
        const SizedBox(height: SbSpace.s2),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wp!.portfolioImages.length.clamp(0, 6),
            separatorBuilder: (_, _) => const SizedBox(width: SbSpace.s2),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(SbRadius.control),
              child: CachedNetworkImage(imageUrl: wp.portfolioImages[i], width: 96, height: 72, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
      if (!compact) ...[
        const SizedBox(height: SbSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.person_outline_rounded, size: 18),
            label: Text(l.proposalViewProfile),
            onPressed: () => context.pushNamed(RouteNames.publicWorkerProfileName,
                pathParameters: {'workerId': proposal.workerId}),
          ),
        ),
      ],
    ]);
  }
}

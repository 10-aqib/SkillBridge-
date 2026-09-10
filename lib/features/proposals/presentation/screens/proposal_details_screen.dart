import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/features/proposals/domain/entities/proposal_entity.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

/// Guild Modernist Proposal Details Screen
class ProposalDetailsScreen extends ConsumerWidget {
  final ProposalEntity? proposal;

  const ProposalDetailsScreen({super.key, this.proposal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = proposal;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          AppL10n.select(context, en: 'Proposal Details', ur: 'تجویز کی تفصیلات'),
          style: AppTextStyles.heading3.copyWith(color: context.textColor),
        ),
      ),
      body: p == null
          ? Center(
              child: Text(
                AppL10n.select(context, en: 'Proposal not found', ur: 'تجویز نہیں ملی'),
                style: AppTextStyles.bodyStrong.copyWith(
                  color: context.mutedColor,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Worker Info Card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    shadow: AppShadows.level1,
                    child: Row(
                      children: [
                        AppAvatar(
                          name: p.workerName,
                          imageUrl: p.workerPhotoUrl,
                          size: 60,
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.workerName,
                                style: AppTextStyles.heading3.copyWith(
                                  color: context.textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.warningOrange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.workerRating.toStringAsFixed(1),
                                    style: AppTextStyles.dataNumeric.copyWith(
                                      color: context.mutedColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _StatusChip(status: p.status),
                      ],
                    ),
                  ).animate().fade(duration: 350.ms),
                  const SizedBox(height: AppDimensions.lg),

                  // Bid Details Card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    shadow: AppShadows.level1,
                    color: AppColors.blueTint,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppL10n.select(context, en: 'Proposed Rate', ur: 'مجوزہ ریٹ (PKR)'),
                              style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rs. ${p.proposedRate.toInt()} / ${p.rateType}',
                              style: AppTextStyles.heading2.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppL10n.select(context, en: 'Duration', ur: 'دورانیہ'),
                              style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.estimatedDuration,
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 100.ms, duration: 350.ms),
                  const SizedBox(height: AppDimensions.lg),

                  // Cover Letter
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    shadow: AppShadows.level1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppL10n.select(context, en: 'Cover Letter', ur: 'تعارفی پیغام'),
                          style: AppTextStyles.heading3.copyWith(
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        Text(
                          p.coverLetter,
                          style: AppTextStyles.bodyPrimary.copyWith(
                            height: 1.7,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms, duration: 350.ms),
                  const SizedBox(height: AppDimensions.xl),

                  // Action Buttons (only visible if pending)
                  if (p.status == ProposalStatus.pending) ...[
                    AppButton(
                      text: AppL10n.select(context, en: 'Accept Proposal', ur: 'تجویز منظور کریں'),
                      onPressed: () async {
                        await ref
                            .read(proposalRemoteDataSourceProvider)
                            .acceptProposal(
                              proposalId: p.id,
                              jobId: p.jobId,
                              workerId: p.workerId,
                              workerName: p.workerName,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Proposal accepted & job assigned to worker.'),
                            ),
                          );
                          GoRouter.of(context).pop();
                        }
                      },
                      width: double.infinity,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    AppButton(
                      text: AppL10n.select(context, en: 'Reject', ur: 'مسترد کریں'),
                      type: AppButtonType.outline,
                      onPressed: () async {
                        await ref
                            .read(proposalRemoteDataSourceProvider)
                            .updateProposalStatus(p.id, 'rejected');
                        if (context.mounted) GoRouter.of(context).pop();
                      },
                      width: double.infinity,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.xl),
                ],
              ),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProposalStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ProposalStatus.pending => (AppL10n.select(context, en: 'Pending', ur: 'زیر التوا'), AppColors.warningOrange),
      ProposalStatus.accepted => (AppL10n.select(context, en: 'Accepted', ur: 'منظور'), AppColors.successGreen),
      ProposalStatus.rejected => (AppL10n.select(context, en: 'Rejected', ur: 'مسترد'), AppColors.errorRed),
      ProposalStatus.withdrawn => (AppL10n.select(context, en: 'Withdrawn', ur: 'واپس'), context.mutedColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

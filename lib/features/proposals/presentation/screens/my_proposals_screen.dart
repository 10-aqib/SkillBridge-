import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_empty_state.dart';
import 'package:skill_bridge/shared/widgets/app_error_widget.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

/// Guild Modernist My Proposals Screen
class MyProposalsScreen extends ConsumerWidget {
  MyProposalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(workerProposalsStreamProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          AppL10n.select(context, en: 'My Proposals', ur: 'میری تجاویز'),
          style: AppTextStyles.heading3.copyWith(color: context.textColor),
        ),
      ),
      body: proposalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => AppErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(workerProposalsStreamProvider),
        ),
        data: (proposals) {
          if (proposals.isEmpty) {
            return AppEmptyState(
              title: AppL10n.select(context, en: 'No Proposals Yet', ur: 'کوئی تجویز نہیں'),
              description:
                  'Browse open jobs and submit proposals to get hired.',
              icon: Icons.description_outlined,
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppDimensions.lg),
            itemCount: proposals.length,
            itemBuilder: (context, index) {
              final p = proposals[index];
              return Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  onTap: () => context.push(
                    RouteNames.proposalDetailsPath,
                    extra: p,
                  ),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    shadow: AppShadows.level1,
                    leftAccentColor: p.status == ProposalStatus.accepted
                        ? AppColors.successGreen
                        : (p.status == ProposalStatus.pending
                            ? AppColors.primary
                            : null),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.jobTitle,
                                style: AppTextStyles.heading3.copyWith(
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ProposalStatusBadge(status: p.status),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          p.coverLetter,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyPrimary.copyWith(
                            color: context.mutedColor,
                          ),
                        ),
                        SizedBox(height: AppDimensions.md),
                        Divider(
                            height: 1, color: context.borderColor),
                        const SizedBox(height: AppDimensions.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppL10n.select(context, en: 'Proposed Rate', ur: 'مجوزہ ریٹ'),
                                  style: AppTextStyles.labelCaption.copyWith(
                                    color: context.mutedColor,
                                  ),
                                ),
                                Text(
                                  'Rs. ${p.proposedRate.toInt()} / ${p.rateType}',
                                  style: AppTextStyles.dataNumeric.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.blueTint,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm),
                              ),
                              child: Text(
                                p.estimatedDuration,
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(delay: (70 * index).ms, duration: 400.ms);
            },
          );
        },
      ),
    );
  }
}

class _ProposalStatusBadge extends StatelessWidget {
  final ProposalStatus status;
  const _ProposalStatusBadge({required this.status});

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
        horizontal: 10,
        vertical: 4,
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

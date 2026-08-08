import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/proposal_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/proposals/data/models/proposal_model.dart';
import 'package:skill_bridge/features/proposals/presentation/providers/proposal_providers.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_badge.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_chip.dart';

/// Guild Modernist Job Details Screen
class JobDetailsScreen extends ConsumerWidget {
  final JobEntity? job;

  const JobDetailsScreen({
    super.key,
    this.job,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final jobData = job;

    final isOwner =
        user != null && jobData != null && user.uid == jobData.clientId;
    final isWorker = user != null && user.isWorker;
    final isAssignedWorker = user != null &&
        jobData != null &&
        user.uid == jobData.selectedWorkerId;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Job Details • کام کی تفصیلات',
          style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
        ),
      ),
      body: jobData == null
          ? Center(
              child: Text(
                'Job details not found.',
                style: AppTextStyles.bodyStrong
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          jobData.title,
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (jobData.urgency == 'urgent') ...[
                        const SizedBox(width: 8),
                        AppBadge.urgent(context),
                      ],
                    ],
                  ).animate().fade(duration: 400.ms),
                  const SizedBox(height: AppDimensions.md),

                  // Category, City & Status Chips
                  Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.sm,
                    children: [
                      AppChip(label: jobData.categoryName),
                      AppChip(label: jobData.city),
                      _buildStatusBadge(jobData.status),
                    ],
                  ).animate().fade(delay: 80.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.xl),

                  // Budget Card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    color: AppColors.blueTint,
                    border: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                    shadow: AppShadows.level1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget (PKR) • بجٹ',
                              style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${jobData.budgetMin.toInt()} - ${jobData.budgetMax.toInt()}',
                              style: AppTextStyles.dataNumeric.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            '${jobData.totalProposals} Proposals',
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 150.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.lg),

                  // Client Information Card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    shadow: AppShadows.level1,
                    child: Row(
                      children: [
                        AppAvatar(
                          name: jobData.clientName,
                          imageUrl: jobData.clientPhotoUrl,
                          size: 50,
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jobData.clientName,
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Posted in ${jobData.city}',
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.xl),

                  // Description
                  Text(
                    'Description • تفصیل',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ).animate().fade(delay: 250.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    jobData.description,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      height: 1.6,
                      color: AppColors.onSurface,
                    ),
                  ).animate().fade(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.space32),

                  // Action Buttons based on status
                  if (jobData.status == JobStatus.open) ...[
                    if (isWorker)
                      AppButton(
                        text: 'Apply / Submit Proposal • تجویز ارسال کریں',
                        onPressed: () => _showSubmitProposalSheet(
                            context, jobData, ref, user),
                        width: double.infinity,
                      ).animate().fade(delay: 350.ms, duration: 400.ms),
                    if (isOwner)
                      AppButton(
                        text:
                            context.l10n.viewReceivedProposals(jobData.totalProposals.toString()),
                        onPressed: () =>
                            _showReceivedProposalsSheet(context, jobData, ref),
                        width: double.infinity,
                      ).animate().fade(delay: 350.ms, duration: 400.ms),
                  ] else if (jobData.status == JobStatus.assigned) ...[
                    if (isOwner || isAssignedWorker)
                      AppButton(
                        text: 'Start Work • کام شروع کریں',
                        onPressed: () async {
                          try {
                            await ref
                                .read(jobRemoteDataSourceProvider)
                                .startJob(jobData.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Job started! Status is now IN PROGRESS • کام شروع ہو گیا ہے'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        width: double.infinity,
                      ).animate().fade(delay: 350.ms, duration: 400.ms),
                  ] else if (jobData.status == JobStatus.inProgress) ...[
                    if (isOwner || isAssignedWorker)
                      AppButton(
                        text: 'Mark as Complete • کام مکمل کریں',
                        onPressed: () async {
                          try {
                            await ref
                                .read(jobRemoteDataSourceProvider)
                                .completeJob(jobData.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Job marked as completed! • کام مکمل ہو گیا ہے'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        width: double.infinity,
                      ).animate().fade(delay: 350.ms, duration: 400.ms),
                  ] else if (jobData.status == JobStatus.completed) ...[
                    if (!jobData.isPaid && isOwner)
                      AppButton(
                        text: 'Pay with EasyPaisa (Rs. ${jobData.budgetMax.toInt()})',
                        onPressed: () async {
                          final success = await context.push<bool>(
                            RouteNames.easyPaisaCheckoutPath,
                            extra: {
                              'jobId': jobData.id,
                              'amount': jobData.budgetMax,
                              'workerName': jobData.selectedWorkerName ?? 'Worker',
                            },
                          );
                          if (success == true) {
                            try {
                              await ref
                                  .read(jobRemoteDataSourceProvider)
                                  .payJob(jobData.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment processed successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        },
                        width: double.infinity,
                      ).animate().fade(delay: 350.ms, duration: 400.ms),
                    if (jobData.isPaid || !isOwner)
                      AppCard(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        color: AppColors.successGreen.withValues(alpha: 0.1),
                        border: BorderSide(
                            color: AppColors.successGreen.withValues(alpha: 0.3)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.successGreen),
                            const SizedBox(width: 8),
                            Text(
                              jobData.isPaid 
                                  ? 'Job Completed & Paid • کام مکمل اور ادا شدہ' 
                                  : 'Job Completed • کام مکمل ہو گیا ہے',
                              style: AppTextStyles.bodyStrong
                                  .copyWith(color: AppColors.successGreen),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: AppDimensions.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge(JobStatus status) {
    String text = 'OPEN • کھلا';
    Color bg = AppColors.successGreen.withValues(alpha: 0.12);
    Color fg = AppColors.successGreen;
    switch (status) {
      case JobStatus.open:
        text = 'OPEN • کھلا';
        bg = AppColors.successGreen.withValues(alpha: 0.12);
        fg = AppColors.successGreen;
        break;
      case JobStatus.assigned:
        text = 'ASSIGNED • منتخب شدہ';
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        break;
      case JobStatus.inProgress:
        text = 'IN PROGRESS • کام جاری';
        bg = AppColors.warningOrange.withValues(alpha: 0.15);
        fg = AppColors.warningOrange;
        break;
      case JobStatus.completed:
        text = 'COMPLETED • مکمل';
        bg = AppColors.successGreen.withValues(alpha: 0.12);
        fg = AppColors.successGreen;
        break;
      case JobStatus.cancelled:
        text = 'CANCELLED • منسوخ';
        bg = AppColors.errorRed.withValues(alpha: 0.12);
        fg = AppColors.errorRed;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelCaption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showSubmitProposalSheet(
    BuildContext context,
    JobEntity job,
    WidgetRef ref,
    dynamic user,
  ) {
    final rateController =
        TextEditingController(text: job.budgetMax.toStringAsFixed(0));
    final durationController = TextEditingController(text: '2-3 Days');
    final coverController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.lg,
          right: AppDimensions.lg,
          top: AppDimensions.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit Proposal • تجویز ارسال کریں',
              style: AppTextStyles.heading2.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Proposed Hourly Rate (PKR)',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(
                labelText: 'Estimated Duration (e.g. 2-3 Days)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: coverController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Cover Note / Letter • تعارفی پیغام',
                hintText: 'Explain why you are the best fit for this job...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            AppButton(
              text: 'Submit Proposal • جمع کرائیں',
              width: double.infinity,
              onPressed: () async {
                final rate =
                    double.tryParse(rateController.text.trim()) ?? job.budgetMax;
                final duration = durationController.text.trim();
                final cover = coverController.text.trim();

                if (cover.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a cover note / letter.')),
                  );
                  return;
                }

                final proposal = ProposalModel(
                  id: '',
                  jobId: job.id,
                  jobTitle: job.title,
                  workerId: user.uid,
                  workerName: user.displayName ?? 'Skill Bridge Worker',
                  workerRating: 4.8,
                  coverLetter: cover,
                  proposedRate: rate,
                  rateType: 'hourly',
                  estimatedDuration: duration,
                  status: ProposalStatus.pending,
                  clientId: job.clientId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  await ref
                      .read(proposalRemoteDataSourceProvider)
                      .submitProposal(proposal);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Proposal submitted successfully! • تجویز ارسال کر دی گئی'),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReceivedProposalsSheet(
    BuildContext context,
    JobEntity job,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final proposalsAsync =
              ref.watch(jobProposalsStreamProvider(job.id));

          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.receivedProposals,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: proposalsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Error loading proposals: $err',
                          style: AppTextStyles.bodyPrimary),
                    ),
                    data: (proposals) {
                      if (proposals.isEmpty) {
                        return Center(
                          child: Text(
                            'No proposals received yet • ابھی کوئی تجویز موصول نہیں ہوئی',
                            style: AppTextStyles.bodyPrimary,
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.lg),
                        itemCount: proposals.length,
                        itemBuilder: (context, index) {
                          final p = proposals[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppDimensions.md),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppDimensions.md),
                              shadow: AppShadows.level1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        p.workerName,
                                        style: AppTextStyles.heading3.copyWith(
                                            color: AppColors.onSurface),
                                      ),
                                      Text(
                                        'Rs. ${p.proposedRate.toInt()}/hr',
                                        style: AppTextStyles.bodyStrong
                                            .copyWith(color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Duration: ${p.estimatedDuration} • Status: ${p.status.value.toUpperCase()}',
                                    style: AppTextStyles.labelCaption.copyWith(
                                        color: AppColors.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.coverLetter,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyPrimary.copyWith(
                                        color: AppColors.onSurface),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          context.push(
                                            RouteNames.proposalDetailsPath
                                                .replaceAll(
                                                    ':proposalId', p.id),
                                            extra: p,
                                          );
                                        },
                                        child: const Text('View Details'),
                                      ),
                                      if (p.status ==
                                          ProposalStatus.pending) ...[
                                        const SizedBox(width: 8),
                                        AppButton(
                                          text: 'Accept • منظور کریں',
                                          isSmall: true,
                                          onPressed: () async {
                                            try {
                                              await ref
                                                  .read(
                                                      proposalRemoteDataSourceProvider)
                                                  .acceptProposal(
                                                    proposalId: p.id,
                                                    jobId: p.jobId,
                                                    workerId: p.workerId,
                                                    workerName: p.workerName,
                                                  );
                                              if (ctx.mounted) {
                                                Navigator.of(ctx).pop();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Proposal accepted & job assigned!'),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (ctx.mounted) {
                                                ScaffoldMessenger.of(ctx)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content:
                                                          Text('Error: $e')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

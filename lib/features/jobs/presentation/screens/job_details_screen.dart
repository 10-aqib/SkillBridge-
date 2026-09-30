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
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/worker_live_tracking_map.dart';

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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          AppL10n.select(context, en: 'Job Details', ur: 'کام کی تفصیلات'),
          style: AppTextStyles.heading3.copyWith(color: context.textColor),
        ),
      ),
      body: jobData == null
          ? Center(
              child: Text(
                'Job details not found.',
                style: AppTextStyles.bodyStrong
                    .copyWith(color: context.mutedColor),
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
                            color: context.textColor,
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
                      _buildStatusBadge(context, jobData.status),
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
                              AppL10n.select(context, en: 'Budget (PKR)', ur: 'بجٹ'),
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
                            color: context.surfaceColor,
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
                                  color: context.textColor,
                                ),
                              ),
                              Text(
                                'Posted in ${jobData.city}',
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: context.mutedColor,
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
                    AppL10n.select(context, en: 'Description', ur: 'تفصیل'),
                    style: AppTextStyles.heading3.copyWith(
                      color: context.textColor,
                    ),
                  ).animate().fade(delay: 250.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    jobData.description,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      height: 1.6,
                      color: context.textColor,
                    ),
                  ).animate().fade(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.space32),

                  // Action Buttons based on status
                  if (jobData.status == JobStatus.open) ...[
                    if (isWorker)
                      AppButton(
                        text: AppL10n.select(context, en: 'Apply / Submit Proposal', ur: 'تجویز ارسال کریں'),
                        onPressed: () => _showSubmitProposalSheet(
                            context, jobData, ref, user),
                        width: double.infinity,
                      ).animate().fade(delay: 350.ms, duration: 400.ms),
                    if (isOwner)
                      AppButton(
                        text:
                            context.l10n.viewReceivedProposals(jobData.totalProposals),
                        onPressed: () =>
                            _showReceivedProposalsSheet(context, jobData, ref),
                        width: double.infinity,
                      ).animate().fade(delay: 350.ms, duration: 400.ms),
                  ] else if (jobData.status == JobStatus.assigned) ...[
                    if (isOwner && jobData.selectedWorkerId != null) ...[
                      WorkerLiveTrackingMap(
                        workerId: jobData.selectedWorkerId!,
                        workerName: jobData.selectedWorkerName ?? 'Assigned Worker',
                        workerPhone: '',
                        clientLat: jobData.location?.latitude ?? 33.6844,
                        clientLon: jobData.location?.longitude ?? 73.0479,
                      ).animate().fade(delay: 300.ms, duration: 400.ms),
                      const SizedBox(height: AppDimensions.lg),
                    ],
                    if (isAssignedWorker) ...[
                      _WorkerLocationSharingCard(
                        jobId: jobData.id,
                        workerUid: user.uid,
                        jobAddress: jobData.address,
                        jobLat: jobData.location?.latitude ?? 33.6844,
                        jobLon: jobData.location?.longitude ?? 73.0479,
                      ).animate().fade(delay: 300.ms, duration: 400.ms),
                      const SizedBox(height: AppDimensions.lg),
                    ],
                    if (isOwner || isAssignedWorker)
                      AppButton(
                        text: AppL10n.select(context, en: 'Start Work', ur: 'کام شروع کریں'),
                        onPressed: () async {
                          try {
                            await ref
                                .read(jobRemoteDataSourceProvider)
                                .startJob(jobData.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      AppL10n.select(context, en: 'Job started! Status is now IN PROGRESS', ur: 'کام شروع ہو گیا ہے')),
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
                    if (isOwner && jobData.selectedWorkerId != null) ...[
                      WorkerLiveTrackingMap(
                        workerId: jobData.selectedWorkerId!,
                        workerName: jobData.selectedWorkerName ?? 'Assigned Worker',
                        workerPhone: '',
                        clientLat: jobData.location?.latitude ?? 33.6844,
                        clientLon: jobData.location?.longitude ?? 73.0479,
                      ).animate().fade(delay: 300.ms, duration: 400.ms),
                      const SizedBox(height: AppDimensions.lg),
                    ],
                    if (isAssignedWorker) ...[
                      _WorkerLocationSharingCard(
                        jobId: jobData.id,
                        workerUid: user.uid,
                        jobAddress: jobData.address,
                        jobLat: jobData.location?.latitude ?? 33.6844,
                        jobLon: jobData.location?.longitude ?? 73.0479,
                      ).animate().fade(delay: 300.ms, duration: 400.ms),
                      const SizedBox(height: AppDimensions.lg),
                    ],
                    if (isOwner || isAssignedWorker)
                      AppButton(
                        text: AppL10n.select(context, en: 'Mark as Complete', ur: 'کام مکمل کریں'),
                        onPressed: () async {
                          try {
                            await ref
                                .read(jobRemoteDataSourceProvider)
                                .completeJob(jobData.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      AppL10n.select(context, en: 'Job marked as completed!', ur: 'کام مکمل ہو گیا ہے')),
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
                                  ? AppL10n.select(context, en: 'Job Completed & Paid', ur: 'کام مکمل اور ادا شدہ') 
                                  : AppL10n.select(context, en: 'Job Completed', ur: 'کام مکمل ہو گیا ہے'),
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

  Widget _buildStatusBadge(BuildContext context, JobStatus status) {
    String text = AppL10n.select(context, en: 'OPEN', ur: 'کھلا');
    Color bg = AppColors.successGreen.withValues(alpha: 0.12);
    Color fg = AppColors.successGreen;
    switch (status) {
      case JobStatus.open:
        text = AppL10n.select(context, en: 'OPEN', ur: 'کھلا');
        bg = AppColors.successGreen.withValues(alpha: 0.12);
        fg = AppColors.successGreen;
        break;
      case JobStatus.assigned:
        text = AppL10n.select(context, en: 'ASSIGNED', ur: 'منتخب شدہ');
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        break;
      case JobStatus.inProgress:
        text = AppL10n.select(context, en: 'IN PROGRESS', ur: 'کام جاری');
        bg = AppColors.warningOrange.withValues(alpha: 0.15);
        fg = AppColors.warningOrange;
        break;
      case JobStatus.completed:
        text = AppL10n.select(context, en: 'COMPLETED', ur: 'مکمل');
        bg = AppColors.successGreen.withValues(alpha: 0.12);
        fg = AppColors.successGreen;
        break;
      case JobStatus.cancelled:
        text = AppL10n.select(context, en: 'CANCELLED', ur: 'منسوخ');
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
      backgroundColor: context.surfaceColor,
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
              AppL10n.select(context, en: 'Submit Proposal', ur: 'تجویز ارسال کریں'),
              style: AppTextStyles.heading2.copyWith(color: context.textColor),
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
              decoration: InputDecoration(
                labelText: AppL10n.select(context, en: 'Cover Note / Letter', ur: 'تعارفی پیغام'),
                hintText: 'Explain why you are the best fit for this job...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            AppButton(
              text: AppL10n.select(context, en: 'Submit Proposal', ur: 'جمع کرائیں'),
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
                      SnackBar(
                        content: Text(
                            AppL10n.select(context, en: 'Proposal submitted successfully!', ur: 'تجویز ارسال کر دی گئی')),
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
      backgroundColor: context.surfaceColor,
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
                              .copyWith(color: context.textColor),
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
                            AppL10n.select(context, en: 'No proposals received yet', ur: 'ابھی کوئی تجویز موصول نہیں ہوئی'),
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
                                            color: context.textColor),
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
                                    AppL10n.select(context, en: 'Duration: ${p.estimatedDuration}', ur: 'Status: ${p.status.value.toUpperCase()}'),
                                    style: AppTextStyles.labelCaption.copyWith(
                                        color: context.mutedColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.coverLetter,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyPrimary.copyWith(
                                        color: context.textColor),
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
                                          text: AppL10n.select(context, en: 'Accept', ur: 'منظور کریں'),
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

class _WorkerLocationSharingCard extends ConsumerWidget {
  final String jobId;
  final String workerUid;
  final String jobAddress;
  final double jobLat;
  final double jobLon;

  const _WorkerLocationSharingCard({
    required this.jobId,
    required this.workerUid,
    required this.jobAddress,
    required this.jobLat,
    required this.jobLon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(userLiveLocationStreamProvider(workerUid));
    final trackingService = ref.watch(locationTrackingServiceProvider);

    final isSharing = locationAsync.when(
      data: (data) => data?['isLocationSharing'] as bool? ?? false,
      loading: () => trackingService.isTracking,
      error: (_, __) => false,
    );

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      shadow: AppShadows.level2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSharing
                      ? AppColors.successGreen.withValues(alpha: 0.12)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSharing ? Icons.location_on : Icons.location_off_outlined,
                  color: isSharing ? AppColors.successGreen : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live GPS Location Sharing',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: context.textColor,
                      ),
                    ),
                    Text(
                      isSharing
                          ? 'Client is receiving your live location'
                          : 'Share location so client can track your arrival',
                      style: AppTextStyles.labelCaption.copyWith(
                        color: isSharing ? AppColors.successGreen : context.mutedColor,
                        fontWeight: isSharing ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isSharing,
                activeTrackColor: AppColors.primary,
                onChanged: (val) async {
                  if (val) {
                    final status = await trackingService.startTracking(workerUid);
                    if (!context.mounted) return;
                    if (status == LocationTrackingStatus.serviceDisabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enable GPS/Location services.'),
                          action: SnackBarAction(
                            label: 'Settings',
                            onPressed: () => trackingService.openLocationSettings(),
                          ),
                        ),
                      );
                    } else if (status == LocationTrackingStatus.permissionDenied ||
                        status == LocationTrackingStatus.permissionPermanentlyDenied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Location permission is required for live tracking.'),
                          action: SnackBarAction(
                            label: 'Settings',
                            onPressed: () => trackingService.openAppSettings(),
                          ),
                        ),
                      );
                    }
                  } else {
                    await trackingService.stopTracking(workerUid);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              const Icon(Icons.navigation_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Job Destination: $jobAddress',
                  style: AppTextStyles.labelCaption.copyWith(
                    color: context.mutedColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


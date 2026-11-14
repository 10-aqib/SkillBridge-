import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/direct_request_actions.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/open_contract_card.dart';

/// The job page's link to the work: direct-request accept/decline while
/// open, then the contract card (start, updates, location, submit, confirm
/// all live on the contract). No payment actions: payments aren't processed
/// in the app.
class JobLifecycleActions extends ConsumerWidget {
  const JobLifecycleActions({super.key, required this.job});
  final JobEntity job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final jobData = job;
    if (user == null) return const SizedBox.shrink();
    final isOwner = user.uid == jobData.clientId;
    final isWorker = user.isWorker;
    final isAssignedWorker = user.uid == jobData.selectedWorkerId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      if (jobData.status == JobStatus.open) ...[
        if (isWorker) ...[
          if (jobData.selectedWorkerId == user.uid) ...[
            // Accepting creates the contract through the trusted function.
            DirectRequestActions(jobId: jobData.id, jobTitle: jobData.title),
          ],
        ],
        if (isOwner) ...[
          if (jobData.selectedWorkerId != null && jobData.selectedWorkerId!.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.md),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Center(
                child: Text(
                  AppL10n.select(context, en: 'Waiting for ${jobData.selectedWorkerName ?? 'Worker'} to accept', ur: 'کارکن کی منظوری کا انتظار ہے'),
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary),
                ),
              ),
            ).animate().fade(delay: 350.ms, duration: 400.ms),
          ],
        ],
      ] else if (jobData.status == JobStatus.assigned || jobData.status == JobStatus.inProgress) ...[
        // Starting, progress updates, live location (Phase 4B, on the
        // contract with the worker's consent) and finishing all happen on
        // the contract, through the trusted functions.
        if (isOwner || isAssignedWorker) OpenContractCard(jobId: jobData.id),
      ] else if (jobData.status == JobStatus.completed) ...[
        if (isOwner || isAssignedWorker) ...[OpenContractCard(jobId: jobData.id), const SizedBox(height: AppDimensions.md)],
        // Payments aren't processed in the app (Phase 4B removed the
        // EasyPaisa button and the "paid" wording that suggested otherwise).
        AppCard(
          padding: const EdgeInsets.all(AppDimensions.md),
          color: AppColors.successGreen.withValues(alpha: 0.1),
          border: BorderSide(color: AppColors.successGreen.withValues(alpha: 0.3)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppL10n.select(context, en: 'Job completed', ur: 'کام مکمل ہو گیا ہے'),
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.successGreen),
                ),
              ),
            ],
          ),
        ),
      ],
      ],
    );
  }
}

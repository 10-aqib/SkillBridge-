import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/worker/presentation/widgets/worker_earnings_chart.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_error_widget.dart';
import 'package:skill_bridge/shared/widgets/job_card.dart';

/// Guild Modernist Worker Dashboard (b1_worker_dashboard)
class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  String _availability = 'Available';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final jobsAsync = ref.watch(openJobsStreamProvider);

    final displayName = user?.displayName ?? 'Worker';
    final photoUrl = user?.photoUrl;
    final rating = user?.workerProfile?.averageRating ?? 0.0;
    final totalCompleted = user?.workerProfile?.totalJobsCompleted ?? 0;
    final hourlyRate = user?.workerProfile?.hourlyRate ?? 1500;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header (Sora + Inter) ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppL10n.select(
                            context,
                            en: 'Worker Dashboard',
                            ur: 'کاریگر ڈیش بورڈ',
                          ),
                          style: AppTextStyles.labelCaption.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppL10n.select(
                            context,
                            en: 'Welcome, $displayName!',
                            ur: 'خوش آمدید، $displayName!',
                          ),
                          style: AppTextStyles.headlineLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    AppAvatar(
                      name: displayName,
                      imageUrl: photoUrl,
                      size: 48,
                    ),
                  ],
                ),
              ),
            ),

            // ── Availability Card ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                ),
                child: AppCard(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  shadow: AppShadows.level2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _availability == 'Available'
                                  ? AppColors.tertiary
                                  : _availability == 'Busy'
                                      ? AppColors.amber
                                      : AppColors.errorRed,
                              boxShadow: [
                                BoxShadow(
                                  color: (_availability == 'Available'
                                          ? AppColors.tertiary
                                          : _availability == 'Busy'
                                              ? AppColors.amber
                                              : AppColors.errorRed)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: $_availability',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _availability == 'Available'
                                    ? AppL10n.select(
                                        context,
                                        en: 'Visible to new clients',
                                        ur: 'کلائنٹس کو نظر آ رہا ہے',
                                      )
                                    : AppL10n.select(
                                        context,
                                        en: 'Hiding from search',
                                        ur: 'سرچ سے پوشیدہ',
                                      ),
                                style: AppTextStyles.bodyPrimary.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) =>
                            setState(() => _availability = val),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Available',
                            child: Text('Available'),
                          ),
                          const PopupMenuItem(
                            value: 'Busy',
                            child: Text('Busy'),
                          ),
                          const PopupMenuItem(
                            value: 'Unavailable',
                            child: Text('Unavailable'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            'Change',
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Quick Stats Grid (Level 1 Surfaces) ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        shadow: AppShadows.level1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppL10n.select(
                                context,
                                en: 'Rating',
                                ur: 'ریٹنگ',
                              ),
                              style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        shadow: AppShadows.level1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppL10n.select(
                                context,
                                en: 'Completed',
                                ur: 'مکمل کام',
                              ),
                              style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalCompleted',
                              style: AppTextStyles.heading2.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        shadow: AppShadows.level1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppL10n.select(
                                context,
                                en: 'Rate',
                                ur: 'اجرت',
                              ),
                              style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. $hourlyRate/hr',
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: AppColors.primary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),

            // ── 7-Day Earnings Chart ────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                child: WorkerEarningsChart(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.md),
            ),

            // ── Section Title: Jobs Nearby You ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppL10n.select(
                        context,
                        en: 'Jobs Nearby You',
                        ur: 'قریبی کام',
                      ),
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(RouteNames.workerProposalsPath),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: AppTextStyles.bodyStrong,
                      ),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Job Feed List (Live Riverpod Stream) ────────────────────────
            jobsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: AppErrorWidget(
                  errorMessage: 'Could not load jobs: $err',
                  onRetry: () => ref.refresh(openJobsStreamProvider),
                ),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No jobs available nearby.',
                          style: AppTextStyles.bodyPrimary.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = jobs[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: AppDimensions.lg,
                          right: AppDimensions.lg,
                          bottom: AppDimensions.md,
                        ),
                        child: JobCard(
                          title: job.title,
                          category: job.categoryName.isNotEmpty
                              ? job.categoryName
                              : job.categoryId,
                          budgetPkr: job.budgetMax > 0
                              ? job.budgetMax
                              : job.budgetMin,
                          budgetType: job.jobType == JobType.permanent
                              ? 'Permanent'
                              : 'Temporary',
                          locationText: job.city.isNotEmpty
                              ? job.city
                              : job.address,
                          clientName: job.clientName,
                          clientRating: 4.9,
                          isUrgent: job.urgency.toLowerCase() == 'urgent',
                          onTap: () {
                            context.push(
                              RouteNames.clientJobDetailsPath,
                              extra: job,
                            );
                          },
                          onApplyTap: () {
                            context.push(
                              RouteNames.clientJobDetailsPath,
                              extra: job,
                            );
                          },
                        ),
                      );
                    },
                    childCount: jobs.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.space48),
            ),
          ],
        ),
      ),
    );
  }
}

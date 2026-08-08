import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/shared/widgets/app_badge.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

/// Enhanced My Jobs Screen — Premium design with tabs, stats, and bilingual support
class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(clientJobsStreamProvider);
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── Gradient App Bar ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF001E60), Color(0xFF1A56DB)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu ? 'میرے کام' : 'My Jobs',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isUrdu
                                ? 'اپنے تمام جاب پوسٹس یہاں دیکھیں'
                                : 'Track and manage all your posted jobs',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: context.surfaceColor,
                  child: jobsAsync.when(
                    data: (jobs) {
                      final openCount = jobs.where((j) => j.status == JobStatus.open).length;
                      final activeCount = jobs.where((j) => j.status == JobStatus.inProgress).length;
                      final doneCount = jobs.where((j) => j.status == JobStatus.completed).length;
                      return TabBar(
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.onSurfaceVariant,
                        labelStyle: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
                        unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        tabs: [
                          Tab(text: isUrdu ? 'کھلے ($openCount)' : 'Open ($openCount)'),
                          Tab(text: isUrdu ? 'جاری ($activeCount)' : 'Active ($activeCount)'),
                          Tab(text: isUrdu ? 'مکمل ($doneCount)' : 'Done ($doneCount)'),
                        ],
                      );
                    },
                    loading: () => const TabBar(tabs: [Tab(text: 'Open'), Tab(text: 'Active'), Tab(text: 'Done')]),
                    error: (_, __) => const TabBar(tabs: [Tab(text: 'Open'), Tab(text: 'Active'), Tab(text: 'Done')]),
                  ),
                ),
              ),
            ),
          ],
          body: jobsAsync.when(
            loading: () => _buildSkeletonLoader(),
            error: (err, _) => _buildError(context, isUrdu),
            data: (jobs) {
              final open =
                  jobs.where((j) => j.status == JobStatus.open).toList();
              final active =
                  jobs.where((j) => j.status == JobStatus.inProgress).toList();
              final done =
                  jobs.where((j) => j.status == JobStatus.completed).toList();

              return TabBarView(
                children: [
                  _JobList(jobs: open, isUrdu: isUrdu,
                      emptyTitle: isUrdu ? 'کوئی کھلا کام نہیں' : 'No Open Jobs',
                      emptySubtitle: isUrdu ? 'نیچے + بٹن سے نیا کام پوسٹ کریں' : 'Post a new job using the button below'),
                  _JobList(jobs: active, isUrdu: isUrdu,
                      emptyTitle: isUrdu ? 'کوئی جاری کام نہیں' : 'No Active Jobs',
                      emptySubtitle: isUrdu ? 'ابھی تک کوئی جاری نہیں' : 'Jobs in progress will appear here'),
                  _JobList(jobs: done, isUrdu: isUrdu,
                      emptyTitle: isUrdu ? 'کوئی مکمل کام نہیں' : 'No Completed Jobs',
                      emptySubtitle: isUrdu ? 'مکمل ہونے والے کام یہاں آئیں گے' : 'Finished jobs will appear here'),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(RouteNames.clientPostJobPath),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isUrdu ? 'نیا کام' : 'Post Job',
            style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isUrdu) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text(
            isUrdu ? 'لوڈ نہیں ہو سکا' : 'Could not load jobs',
            style:
                AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            isUrdu ? 'انٹرنیٹ کنکشن چیک کریں' : 'Check your internet connection',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.surfaceContainerHigh, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(width: 150, height: 16, color: AppColors.surfaceContainerHigh),
                  ],
                ),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 12, color: AppColors.surfaceContainerHigh),
                const SizedBox(height: 6),
                Container(width: 200, height: 12, color: AppColors.surfaceContainerHigh),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(width: 80, height: 24, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(width: 8),
                    Container(width: 80, height: 24, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .fade(begin: 0.5, end: 1.0, duration: 800.ms),
        );
      },
    );
  }
}

class _JobList extends ConsumerWidget {
  final List<JobEntity> jobs;
  final bool isUrdu;
  final String emptyTitle;
  final String emptySubtitle;

  const _JobList({
    required this.jobs,
    required this.isUrdu,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_off_outlined,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(emptyTitle,
                style: AppTextStyles.heading3
                    .copyWith(color: context.textColor)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                emptySubtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.clientPostJobPath),
              icon: const Icon(Icons.add_rounded),
              label: Text(isUrdu ? 'نیا کام پوسٹ کریں' : 'Post a Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final isUrgent = job.urgency == 'urgent';
        final statusColor = job.status == JobStatus.open
            ? AppColors.successGreen
            : job.status == JobStatus.inProgress
                ? AppColors.primaryLight
                : AppColors.onSurfaceVariant;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () =>
                context.push(RouteNames.clientJobDetailsPath, extra: job),
            child: AppCard(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Status indicator dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.title,
                          style: AppTextStyles.heading3.copyWith(
                            color: context.textColor,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isUrgent) AppBadge.urgent(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.payments_outlined,
                        label: 'Rs. ${job.budgetMin.toInt()}–${job.budgetMax.toInt()}',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.description_outlined,
                        label: '${job.totalProposals} ${isUrdu ? 'تجاویز' : 'Proposals'}',
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.location_on_outlined,
                        label: job.city.isEmpty ? 'Lahore' : job.city,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  if (job.status == JobStatus.open) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            ref
                                .read(jobRemoteDataSourceProvider)
                                .updateJob(job.id, {'status': 'cancelled'});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(isUrdu
                                      ? 'کام منسوخ کر دیا گیا'
                                      : 'Job cancelled.')),
                            );
                          },
                          icon: const Icon(Icons.cancel_outlined,
                              size: 15, color: AppColors.errorRed),
                          label: Text(
                            isUrdu ? 'منسوخ' : 'Cancel',
                            style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.errorRed),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context
                              .push(RouteNames.clientJobDetailsPath, extra: job),
                          icon: const Icon(Icons.visibility_outlined,
                              size: 15, color: AppColors.primary),
                          label: Text(
                            isUrdu ? 'تفصیل' : 'View',
                            style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fade(delay: (60 * index).ms, duration: 350.ms),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelCaption.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

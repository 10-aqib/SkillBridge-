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
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/worker/presentation/widgets/worker_earnings_chart.dart';
import 'package:skill_bridge/core/utils/formatters.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_error_widget.dart';
import 'package:skill_bridge/shared/widgets/job_card.dart';
import 'package:skill_bridge/shared/widgets/rating_badge.dart';

/// Guild Modernist Worker Dashboard (b1_worker_dashboard)
class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  String _availability = 'Available';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      final a = user?.workerProfile?.availability;
      if (a != null && mounted) {
        setState(() {
          if (a.toLowerCase() == 'busy') {
            _availability = 'Busy';
          } else if (a.toLowerCase() == 'unavailable' ||
              a.toLowerCase() == 'offline') {
            _availability = 'Unavailable';
          } else {
            _availability = 'Available';
          }
        });
      }
    });
  }

  Future<void> _updateAvailability(String val) async {
    setState(() => _availability = val);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref.read(updateUserProfileUseCaseProvider).call(
              uid: user.uid,
              data: {
                'workerProfile.availability': val.toLowerCase(),
              },
            );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final jobsAsync = ref.watch(openJobsStreamProvider);

    final displayName = user?.formattedDisplayName ?? 'Worker';
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
                          'Worker Dashboard',
                          style: AppTextStyles.labelCaption.copyWith(
                            color: context.mutedColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome, $displayName!',
                          style: AppTextStyles.headlineLg.copyWith(
                            color: context.textColor,
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
                                  color: context.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _availability == 'Available'
                                    ? 'Visible to new clients'
                                    : 'Hiding from search',
                                style: AppTextStyles.bodyPrimary.copyWith(
                                  color: context.mutedColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: _updateAvailability,
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
                              'Rating',
                              style: AppTextStyles.labelCaption.copyWith(
                                color: context.mutedColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RatingBadge(
                              rating: rating,
                              reviewCount: user?.totalReviews ?? 0,
                              showReviewCount: false,
                              textStyle: AppTextStyles.heading2.copyWith(
                                color: context.textColor,
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
                              'Completed',
                              style: AppTextStyles.labelCaption.copyWith(
                                color: context.mutedColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalCompleted',
                              style: AppTextStyles.heading2.copyWith(
                                color: context.textColor,
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
                              'Rate',
                              style: AppTextStyles.labelCaption.copyWith(
                                color: context.mutedColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${Formatters.formatPkr(hourlyRate)}/hr',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                child: WorkerEarningsChart(totalCompleted: totalCompleted),
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
                      'Jobs Nearby You',
                      style: AppTextStyles.heading2.copyWith(
                        color: context.textColor,
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
              data: (allJobs) {
                // Filter and sort nearby jobs
                var nearbyJobs = allJobs.where((j) => j.clientId != user?.uid).toList();

                if (user?.location != null) {
                  // Sort by distance
                  nearbyJobs.sort((a, b) {
                    final distA = a.location != null
                        ? GeoLocationUtil.calculateDistanceKm(
                            user!.location!.latitude, user.location!.longitude,
                            a.location!.latitude, a.location!.longitude)
                        : 9999.0;
                    final distB = b.location != null
                        ? GeoLocationUtil.calculateDistanceKm(
                            user!.location!.latitude, user.location!.longitude,
                            b.location!.latitude, b.location!.longitude)
                        : 9999.0;
                    return distA.compareTo(distB);
                  });
                  // Filter out jobs too far away (e.g. > 50km)
                  nearbyJobs = nearbyJobs.where((j) {
                    if (j.location == null) return j.city == user!.city;
                    final dist = GeoLocationUtil.calculateDistanceKm(
                        user!.location!.latitude, user.location!.longitude,
                        j.location!.latitude, j.location!.longitude);
                    return dist <= 50.0;
                  }).toList();
                } else if (user?.city != null) {
                  nearbyJobs = nearbyJobs.where((j) => j.city == user!.city).toList();
                }

                if (nearbyJobs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No jobs available nearby.',
                          style: AppTextStyles.bodyPrimary.copyWith(
                            color: context.mutedColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = nearbyJobs[index];
                      
                      String locText = job.city.isNotEmpty ? job.city : job.address;
                      if (user?.location != null && job.location != null) {
                        final dist = GeoLocationUtil.calculateDistanceKm(
                          user!.location!.latitude, user.location!.longitude,
                          job.location!.latitude, job.location!.longitude
                        );
                        locText = '${GeoLocationUtil.formatInDriveDistance(dist)} • $locText';
                      }

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
                          locationText: locText,
                          clientName: job.clientName.trim().isNotEmpty ? job.clientName.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ') : 'Client',
                          clientRating: 5.0, // Should be job.clientRating if available
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
                    childCount: nearbyJobs.length,
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


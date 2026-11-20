import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/worker/presentation/widgets/worker_earnings_chart.dart';
import 'package:skill_bridge/core/utils/formatters.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';

// ── Dark Premium Design Tokens ────────────────────────────────────────────────
const _bg = Color(0xFF0B0F19);
const _card = Color(0xFF131A27);
const _surface2 = Color(0xFF192233);
const _textPrimary = Color(0xFFF5F6FA);
const _textSecondary = Color(0xFF929BAA);
const _border = Color(0xFF252F40);
const _accent = Color(0xFF4778E8);
const _success = Color(0xFF22C58B);

/// Minimal Premium Worker Dashboard — dark-forced, banking-app inspired.
class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  String _availability = 'Available';
  bool _savingAvailability = false;

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

  /// Saves first and only then shows the new status, so the worker never
  /// sees a status that clients don't. 'Unavailable' is stored as 'offline',
  /// the value the rest of the app (Availability enum, profile screen,
  /// client cards) understands.
  Future<void> _updateAvailability(String val) async {
    final user = ref.read(currentUserProvider);
    if (user == null || _savingAvailability || val == _availability) return;
    final stored = switch (val) {
      'Busy' => 'busy',
      'Unavailable' => 'offline',
      _ => 'available',
    };
    setState(() => _savingAvailability = true);
    final result = await ref.read(updateUserProfileUseCaseProvider).call(
          uid: user.uid,
          data: {'workerProfile.availability': stored},
        );
    if (!mounted) return;
    setState(() {
      _savingAvailability = false;
      if (result.isRight()) _availability = val;
    });
    if (result.isLeft()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileSaveFailed),
          backgroundColor: const Color(0xFFEF5350),
        ),
      );
    }
  }

  Color get _availabilityColor {
    switch (_availability) {
      case 'Busy':
        return const Color(0xFFFFA726);
      case 'Unavailable':
        return const Color(0xFFEF5350);
      default:
        return _success;
    }
  }

  String get _availabilityDescription {
    switch (_availability) {
      case 'Busy':
        return 'Temporarily unavailable';
      case 'Unavailable':
        return 'Hidden from employers';
      default:
        return "You're visible to employers";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final jobsAsync = ref.watch(openJobsStreamProvider);
    final directRequestsAsync = ref.watch(workerDirectRequestsStreamProvider);

    final firstName =
        (user?.formattedDisplayName ?? 'Worker').split(' ').first;
    final photoUrl = user?.photoUrl;
    final displayName = user?.formattedDisplayName ?? 'Worker';
    final rating = user?.workerProfile?.averageRating ?? 0.0;
    final totalCompleted = user?.workerProfile?.totalJobsCompleted ?? 0;
    final hourlyRate = user?.workerProfile?.hourlyRate ?? 1500;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: branding + bell + avatar
                    Row(
                      children: [
                        // SkillBridge logo text
                        Expanded(child: _SkillBridgeLogo()),
                        const SizedBox(width: 8),
                        // Notification bell
                        _NotificationBell(),
                        const SizedBox(width: 10),
                        // Profile avatar
                        AppAvatar(
                          name: displayName,
                          imageUrl: photoUrl,
                          size: 40,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Welcome copy
                    Text(
                      'Welcome back,',
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: _textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$firstName!',
                      style: AppTextStyles.displayHero.copyWith(
                        color: _textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grow your skills. Build your career.',
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Availability Card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      // Status icon square with tinted background
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _availabilityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.work_outline_rounded,
                          color: _availabilityColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _availabilityColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _availability,
                                    style: AppTextStyles.bodyStrong.copyWith(
                                      color: _textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _availabilityDescription,
                              style: AppTextStyles.labelCaption.copyWith(
                                color: _textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Change pill button
                      PopupMenuButton<String>(
                        enabled: !_savingAvailability,
                        onSelected: _updateAvailability,
                        color: _card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _border),
                        ),
                        itemBuilder: (context) => [
                          _popupItem('Available'),
                          _popupItem('Busy'),
                          _popupItem('Unavailable'),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _surface2,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Change',
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: _textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: _textPrimary,
                                size: 15,
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

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Stats Row ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.15,
                  child: Row(
                    children: [
                      // Rating
                      Expanded(
                        child: _StatCard(
                          icon: Icons.star_rounded,
                          iconColor: _accent,
                          label: 'Rating',
                          value: rating > 0
                              ? rating.toStringAsFixed(1)
                              : '—',
                          valueSuffix: ' / 5',
                          sub: '+0.2 this month',
                          subColor: _success,
                          subIcon: Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Completed
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_rounded,
                          iconColor: _success,
                          label: 'Completed',
                          value: '$totalCompleted',
                          sub: '+2 this month',
                          subColor: _success,
                          subIcon: Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Hourly Rate
                      Expanded(
                        child: _StatCard(
                          icon: Icons.monetization_on_outlined,
                          iconColor: _accent,
                          label: 'Rate',
                          value: 'Rs. ${hourlyRate.toStringAsFixed(0)}',
                          valueSuffix: ' / hr',
                          sub: '',
                          subColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Earnings Chart ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: WorkerEarningsChart(totalCompleted: totalCompleted),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Opportunity Banner ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _OpportunityBanner(
                  onBrowse: () =>
                      context.push(RouteNames.workerJobFeedPath),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Recent Activity ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: _textPrimary,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Recent Activity',
                              style: AppTextStyles.heading3.copyWith(
                                color: _textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          context.push(RouteNames.workerProposalsPath),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: AppTextStyles.labelCaption.copyWith(
                              color: _accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_rounded,
                              color: _accent, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Recent Activity list (direct requests)
            directRequestsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: _ActivityLoading(),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: _ActivityEmpty(),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return const SliverToBoxAdapter(child: _ActivityEmpty());
                }
                final shown = requests.take(3).toList();
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < shown.length; i++) ...[
                          _ActivityItem(
                            title: shown[i].title,
                            subtitle: shown[i].city.isNotEmpty
                                ? shown[i].city
                                : shown[i].address,
                            budget: shown[i].budgetMax > 0
                                ? shown[i].budgetMax
                                : shown[i].budgetMin,
                            isUrgent:
                                shown[i].urgency.toLowerCase() == 'urgent',
                            onTap: () => context.push(
                              RouteNames.jobDetailsLocation(shown[i].id),
                              extra: shown[i],
                            ),
                          ),
                          if (i < shown.length - 1)
                            const Divider(
                                height: 1, color: _border, indent: 16),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Nearby Jobs ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Jobs Nearby You',
                        style: AppTextStyles.heading3.copyWith(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          context.push(RouteNames.workerJobFeedPath),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See All',
                            style: AppTextStyles.labelCaption.copyWith(
                              color: _accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_rounded,
                              color: _accent, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Nearby jobs list
            jobsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (err, __) => SliverToBoxAdapter(
                child: _EmptySection(
                  icon: Icons.error_outline_rounded,
                  message: 'Could not load jobs',
                  sub: 'Pull to refresh',
                  actionLabel: 'Retry',
                  onAction: () => ref.refresh(openJobsStreamProvider),
                ),
              ),
              data: (allJobs) {
                var nearbyJobs = allJobs
                    .where((j) =>
                        j.clientId != user?.uid &&
                        j.selectedWorkerId == null)
                    .toList();

                if (user?.location != null) {
                  nearbyJobs.sort((a, b) {
                    final distA = a.location != null
                        ? GeoLocationUtil.calculateDistanceKm(
                            user!.location!.latitude,
                            user.location!.longitude,
                            a.location!.latitude,
                            a.location!.longitude)
                        : 9999.0;
                    final distB = b.location != null
                        ? GeoLocationUtil.calculateDistanceKm(
                            user!.location!.latitude,
                            user.location!.longitude,
                            b.location!.latitude,
                            b.location!.longitude)
                        : 9999.0;
                    return distA.compareTo(distB);
                  });
                  nearbyJobs = nearbyJobs.where((j) {
                    if (j.location == null) return j.city == user!.city;
                    final dist = GeoLocationUtil.calculateDistanceKm(
                        user!.location!.latitude,
                        user.location!.longitude,
                        j.location!.latitude,
                        j.location!.longitude);
                    return dist <= 50.0;
                  }).toList();
                } else if (user?.city != null) {
                  nearbyJobs = nearbyJobs
                      .where((j) => j.city == user!.city)
                      .toList();
                }

                if (nearbyJobs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptySection(
                      icon: Icons.location_off_outlined,
                      message: 'No jobs nearby',
                      sub: 'Browse all available jobs',
                      actionLabel: 'Browse Jobs',
                      onAction: () =>
                          context.push(RouteNames.workerJobFeedPath),
                    ),
                  );
                }

                final shown = nearbyJobs.take(5).toList();
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < shown.length; i++) ...[
                          Builder(builder: (ctx) {
                            final job = shown[i];
                            String locText = job.city.isNotEmpty
                                ? job.city
                                : job.address;
                            if (user?.location != null &&
                                job.location != null) {
                              final dist =
                                  GeoLocationUtil.calculateDistanceKm(
                                user!.location!.latitude,
                                user.location!.longitude,
                                job.location!.latitude,
                                job.location!.longitude,
                              );
                              locText =
                                  '${GeoLocationUtil.formatInDriveDistance(dist)} • $locText';
                            }
                            return _NearbyJobItem(
                              title: job.title,
                              category: job.categoryName.isNotEmpty
                                  ? job.categoryName
                                  : job.categoryId,
                              locationText: locText,
                              budgetPkr: job.budgetMax > 0
                                  ? job.budgetMax
                                  : job.budgetMin,
                              budgetType:
                                  job.jobType == JobType.permanent
                                      ? 'Permanent'
                                      : 'Temporary',
                              isUrgent:
                                  job.urgency.toLowerCase() == 'urgent',
                              onTap: () => context.push(
                                RouteNames.jobDetailsLocation(job.id),
                                extra: job,
                              ),
                            );
                          }),
                          if (i < shown.length - 1)
                            const Divider(
                                height: 1, color: _border, indent: 16),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String val) {
    return PopupMenuItem<String>(
      value: val,
      child: Text(
        val,
        style: AppTextStyles.bodyPrimary.copyWith(color: _textPrimary),
      ),
    );
  }
}

// ── SkillBridge Logo ──────────────────────────────────────────────────────────
class _SkillBridgeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B7FFF), Color(0xFF3861FB)],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontFamily: 'Sora',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Skill',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              fontFamily: 'Sora',
            ),
          ),
          const Text(
            'Bridge',
            style: TextStyle(
              color: _accent,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              fontFamily: 'Sora',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Bell ─────────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: _textSecondary,
            size: 20,
          ),
        ),
        // Red unread notification dot
        Positioned(
          top: 7,
          right: 7,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFEF5350),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? valueSuffix;
  final String sub;
  final Color subColor;
  final IconData? subIcon;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueSuffix,
    required this.sub,
    required this.subColor,
    this.subIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelCaption.copyWith(
              color: _textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          // Value + optional suffix in single line
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                if (valueSuffix != null)
                  Text(
                    valueSuffix!,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 14,
            child: sub.isNotEmpty
                ? Row(
                    children: [
                      if (subIcon != null) ...[
                        Icon(subIcon, color: subColor, size: 10),
                        const SizedBox(width: 2),
                      ],
                      Expanded(
                        child: Text(
                          sub,
                          style: AppTextStyles.labelCaption.copyWith(
                            color: subColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Opportunity Banner ────────────────────────────────────────────────────────
class _OpportunityBanner extends StatelessWidget {
  final VoidCallback onBrowse;

  const _OpportunityBanner({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: _textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Earnings Yet',
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete your first job to start earning and unlock more opportunities.',
                  style: AppTextStyles.labelCaption.copyWith(
                    color: _textSecondary,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onBrowse,
            style: TextButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Browse Jobs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity List Item ────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double budget;
  final bool isUrgent;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.budget,
    required this.isUrgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: _textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: _textPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUrgent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF5350).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Urgent',
                            style: TextStyle(
                              color: Color(0xFFEF5350),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelCaption.copyWith(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Formatters.formatPkrCompact(budget),
              style: const TextStyle(
                color: _accent,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby Job Item ───────────────────────────────────────────────────────────
class _NearbyJobItem extends StatelessWidget {
  final String title;
  final String category;
  final String locationText;
  final double budgetPkr;
  final String budgetType;
  final bool isUrgent;
  final VoidCallback onTap;

  const _NearbyJobItem({
    required this.title,
    required this.category,
    required this.locationText,
    required this.budgetPkr,
    required this.budgetType,
    required this.isUrgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isUrgent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Location
                const Icon(Icons.location_on_outlined,
                    color: _textSecondary, size: 12),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    locationText,
                    style: AppTextStyles.labelCaption.copyWith(
                      color: _textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Budget
                Text(
                  '${Formatters.formatPkrCompact(budgetPkr)} · $budgetType',
                  style: const TextStyle(
                    color: _accent,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity Loading Placeholder ──────────────────────────────────────────────
class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
      ),
    );
  }
}

// ── Activity Empty State ──────────────────────────────────────────────────────
class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: _textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No recent activity',
            style: AppTextStyles.bodyStrong.copyWith(
              color: _textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your latest updates will appear here.',
            style: AppTextStyles.labelCaption.copyWith(
              color: _textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Generic Empty Section ─────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptySection({
    required this.icon,
    required this.message,
    required this.sub,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyStrong.copyWith(
              color: _textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: AppTextStyles.labelCaption.copyWith(
              color: _textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Line Chart Painter ────────────────────────────────────────────────────────
class PremiumLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final Color dotColor;

  const PremiumLineChartPainter({
    required this.values,
    this.lineColor = _accent,
    this.gridColor = _border,
    this.dotColor = _accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(math.max);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    // Grid lines (4 horizontal)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (1 - i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Build smooth curve path
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.20),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final step = size.width / (values.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height * (1 - (values[i] / effectiveMax) * 0.85) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * step;
        final prevY =
            size.height * (1 - (values[i - 1] / effectiveMax) * 0.85) - 4;
        final cpX1 = prevX + step / 2;
        final cpX2 = x - step / 2;
        path.cubicTo(cpX1, prevY, cpX2, y, x, y);
        fillPath.cubicTo(cpX1, prevY, cpX2, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Dots at data points
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFF131A27)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height * (1 - (values[i] / effectiveMax) * 0.85) - 4;
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(PremiumLineChartPainter old) =>
      old.values != values;
}

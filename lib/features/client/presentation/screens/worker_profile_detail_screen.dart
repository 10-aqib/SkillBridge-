import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/presentation/open_job_chat.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:skill_bridge/features/reviews/data/models/review_model.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/features/identity/presentation/verification_status_widget.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

/// Public worker profile (what clients see). Trust evidence first: identity,
/// verification (only when staff verified), rating with review count (only
/// when reviews exist), completed jobs, rate basis, approximate service area —
/// never a home address or anything from the private verification record.
class WorkerProfileDetailScreen extends ConsumerStatefulWidget {
  final String workerId;

  const WorkerProfileDetailScreen({super.key, required this.workerId});

  @override
  ConsumerState<WorkerProfileDetailScreen> createState() =>
      _WorkerProfileDetailScreenState();
}

class _WorkerProfileDetailScreenState
    extends ConsumerState<WorkerProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final workerAsync = ref.watch(workerProfileProvider(widget.workerId));
    final viewerId = ref.watch(currentUserProvider)?.uid;
    final isOwnProfile = viewerId == widget.workerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.publicProfileTitle),
        actions: [
          if (!isOwnProfile && workerAsync.value != null)
            IconButton(
              tooltip: l.reportProfile,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _reportWorker(context, ref, workerAsync.value!),
            ),
        ],
      ),
      body: workerAsync.when(
        loading: () => const SbProfileSkeleton(),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.publicProfileLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(workerProfileProvider(widget.workerId)),
        ),
        data: (worker) {
          if (worker == null || worker.workerProfile == null) {
            return SbStateView(
              kind: SbStateKind.empty,
              icon: Icons.person_search_outlined,
              title: l.publicProfileNotFound,
              message: l.publicProfileNotFoundBody,
            );
          }
          final profile = worker.workerProfile!;
          final edge = SbLayout.edge(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(edge, SbSpace.s2, edge, SbSpace.s8),
            children: [
              SbReadableWidth(
                maxWidth: 720,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (isOwnProfile) ...[
                    SbInlineBanner(message: l.publicProfileOwnPreview, tone: SbTone.info, icon: Icons.visibility_outlined),
                    const SizedBox(height: SbSpace.s4),
                  ],
                  _Header(worker: worker, profile: profile),
                  const SizedBox(height: SbSpace.s4),
                  _TrustStats(worker: worker, profile: profile),
                  const SizedBox(height: SbSpace.s5),
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: l.about),
                      Tab(text: l.publicProfileWorkTab),
                      Tab(text: l.reviews),
                    ],
                  ),
                  const SizedBox(height: SbSpace.s4),
                  switch (_tabController.index) {
                    1 => _Gallery(profile: profile),
                    2 => _ReviewsTabWidget(workerId: worker.uid, profile: profile),
                    _ => _About(worker: worker, profile: profile),
                  },
                ]),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: (workerAsync.value?.workerProfile != null && !isOwnProfile)
          ? _ActionBar(worker: workerAsync.value!)
          : null,
    );
  }

  Future<void> _reportWorker(BuildContext context, WidgetRef ref, UserEntity worker) async {
    final l = context.l10n;
    final reasons = <String, String>{
      'Safety concern': l.reportReasonSafety,
      'Misleading profile or credentials': l.reportReasonMisleading,
      'Inappropriate conduct': l.reportReasonConduct,
      'Other': l.reportReasonOther,
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(SbSpace.s5, 0, SbSpace.s5, SbSpace.s2),
            child: Text(l.reportProfileTitle, style: Theme.of(sheetContext).textTheme.titleLarge),
          ),
          for (final entry in reasons.entries)
            ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.pop(sheetContext, entry.key),
            ),
        ]),
      ),
    );
    if (reason == null) return;

    final reporterId = ref.read(currentUserProvider)?.uid;
    if (reporterId == null) return;
    try {
      // Stored reason stays in English (admin review queue).
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': reporterId,
        'targetUserId': worker.uid,
        'targetType': 'worker_profile',
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) context.showSnackBar(l.reportSubmitted);
    } catch (_) {
      if (context.mounted) context.showSnackBar(l.reportFailed, isError: true);
    }
  }
}

String _categoryLabel(BuildContext context, WorkerProfileEntity p) {
  for (final c in PakistanConstants.categories) {
    if (c['id'] == p.categoryId || (c['name'] as String).toLowerCase() == p.categoryName.toLowerCase()) {
      return context.isUrdu ? c['urdu'] as String : c['name'] as String;
    }
  }
  return p.categoryName;
}

/// "Rs 800 / hour", "Rs 5,000 / day" or "Rate on request" — never a made-up number.
String workerRateLabel(BuildContext context, WorkerProfileEntity p) {
  final l = context.l10n;
  String rs(double v) => 'Rs ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  if (p.hourlyRate > 0) return l.rateHourly(rs(p.hourlyRate));
  if (p.dailyRate > 0) return l.rateDaily(rs(p.dailyRate));
  return l.rateOnRequest;
}

class _Header extends StatelessWidget {
  const _Header({required this.worker, required this.profile});
  final UserEntity worker;
  final WorkerProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final available = profile.availability == 'available';
    return Column(children: [
      SbAvatar(name: worker.displayName, imageUrl: worker.photoUrl, size: 96),
      const SizedBox(height: SbSpace.s3),
      Text(worker.formattedDisplayName, style: t.headlineSmall, textAlign: TextAlign.center),
      const SizedBox(height: SbSpace.s1),
      if (profile.headline.isNotEmpty)
        Text(profile.headline, style: t.bodyLarge, textAlign: TextAlign.center),
      Text(
        [
          _categoryLabel(context, profile),
          if (profile.experience > 0) l.yearsExperience(profile.experience),
        ].where((s) => s.isNotEmpty).join(' · '),
        style: t.bodyMedium!.copyWith(color: c.textSecondary),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: SbSpace.s3),
      Wrap(alignment: WrapAlignment.center, spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
        IdentityBadges(user: worker),
        available
            ? SbStatusBadge.available(label: l.available)
            : SbStatusBadge.unavailable(label: profile.availability == 'busy' ? l.busy : l.offline),
      ]),
    ]);
  }
}

class _TrustStats extends StatelessWidget {
  const _TrustStats({required this.worker, required this.profile});
  final UserEntity worker;
  final WorkerProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final hasReviews = profile.totalReviews > 0;
    Widget stat(String value, String label, {Widget? icon}) => Expanded(
          child: MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SbSpace.s3, horizontal: SbSpace.s1),
              child: Column(children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Text(value, style: SbTypography.numeric(t.titleMedium!), textAlign: TextAlign.center)),
                  ?icon,
                ]),
                Text(label, style: t.bodySmall, textAlign: TextAlign.center),
              ]),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(SbRadius.card),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            hasReviews
                ? stat(profile.averageRating.toStringAsFixed(1), l.profileReviewsCount(profile.totalReviews),
                    icon: Padding(padding: const EdgeInsetsDirectional.only(start: 2), child: Icon(Icons.star_rounded, size: 16, color: c.accent)))
                : stat(l.publicProfileNew, l.profileNoReviews),
            VerticalDivider(width: 1, color: c.border),
            stat('${profile.totalJobsCompleted}', l.publicProfileJobsDone),
            VerticalDivider(width: 1, color: c.border),
            stat('${worker.createdAt.year}', l.publicProfileMemberSince),
          ]),
        ),
      ),
      const SizedBox(height: SbSpace.s3),
      Container(
        padding: const EdgeInsets.all(SbSpace.s4),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(SbRadius.card),
        ),
        child: Row(children: [
          Icon(Icons.payments_outlined, color: c.primary),
          const SizedBox(width: SbSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(workerRateLabel(context, profile), style: SbTypography.numeric(t.titleSmall!)),
              Text(l.publicProfilePriceNote, style: t.bodySmall),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class _About extends StatelessWidget {
  const _About({required this.worker, required this.profile});
  final UserEntity worker;
  final WorkerProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    Widget heading(String s) => Padding(
          padding: const EdgeInsets.only(top: SbSpace.s5, bottom: SbSpace.s2),
          child: Semantics(header: true, child: Text(s, style: t.titleMedium)),
        );
    final area = profile.city.isNotEmpty ? profile.city : (worker.city ?? '');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(profile.bio.trim().isEmpty ? l.publicProfileNoBio : profile.bio,
          style: t.bodyLarge!.copyWith(color: profile.bio.trim().isEmpty ? c.textSecondary : c.text)),
      if (profile.skills.isNotEmpty) ...[
        heading(l.skills),
        Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
          for (final s in profile.skills) Chip(label: Text(s)),
        ]),
      ],
      heading(l.publicProfileServiceArea),
      Row(children: [
        Icon(Icons.near_me_outlined, size: 20, color: c.textSecondary),
        const SizedBox(width: SbSpace.s2),
        Expanded(
          child: Text(
            area.isEmpty ? l.profileNotAdded : l.publicProfileAreaValue(area, profile.serviceRadius.round()),
            style: t.bodyLarge,
          ),
        ),
      ]),
      const SizedBox(height: SbSpace.s1),
      Text(l.publicProfileAreaPrivacy, style: t.bodySmall),
      if (profile.languages.isNotEmpty) ...[
        heading(l.workerSetupLanguages),
        Text(profile.languages.join(', '), style: t.bodyLarge),
      ],
    ]);
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.profile});
  final WorkerProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.sb;
    final images = [...profile.portfolioImages, ...profile.beforeAfterImages];
    if (images.isEmpty) {
      return SbStateView(
        kind: SbStateKind.empty,
        compact: true,
        icon: Icons.photo_library_outlined,
        title: l.publicProfileNoPhotos,
      );
    }
    return GridView.count(
      crossAxisCount: SbWindowSize.of(context) == SbWindowSize.compact ? 3 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: SbSpace.s2,
      crossAxisSpacing: SbSpace.s2,
      children: [
        for (final (i, url) in images.indexed)
          Semantics(
            button: true,
            label: l.publicProfilePhotoN(i + 1, images.length),
            child: InkWell(
              borderRadius: BorderRadius.circular(SbRadius.control),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SbRadius.control),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const SbSkeleton(height: double.infinity, radius: SbRadius.control),
                  errorWidget: (_, _, _) => ColoredBox(color: c.surfaceSunken, child: Icon(Icons.broken_image_outlined, color: c.textSecondary)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.worker});
  final UserEntity worker;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _opening = false;

  UserEntity get worker => widget.worker;

  /// Opens (or creates) this client's conversation with the worker through
  /// the trusted function.
  Future<void> _message() async {
    setState(() => _opening = true);
    final ok = await openDirectChat(context, ref, workerId: worker.uid);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!ok) context.showSnackBar(context.l10n.jobMessageFailed, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.sb;
    // Conversations outside a job are started by clients only.
    final isClient = ref.watch(currentUserProvider)?.isClient ?? false;
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
      padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s3, SbLayout.edge(context), SbSpace.s3),
      child: SafeArea(
        top: false,
        // Message keeps its natural width (a fixed share cut it to "Mess…" on
        // phones); booking takes the rest.
        child: Row(children: [
          if (isClient) ...[
            SbButton(
              label: l.message,
              icon: Icons.chat_bubble_outline_rounded,
              variant: SbButtonVariant.secondary,
              isLoading: _opening,
              onPressed: _opening ? null : _message,
            ),
            const SizedBox(width: SbSpace.s3),
          ],
          Expanded(
            child: SbButton(
              label: l.publicProfileRequestBooking,
              expand: true,
              onPressed: () => context.push(
                RouteNames.clientPostJobPath,
                extra: {'workerId': worker.uid, 'workerName': worker.formattedDisplayName},
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReviewsTabWidget extends ConsumerStatefulWidget {
  final String workerId;
  final WorkerProfileEntity profile;

  const _ReviewsTabWidget({required this.workerId, required this.profile});

  @override
  ConsumerState<_ReviewsTabWidget> createState() => _ReviewsTabWidgetState();
}

class _ReviewsTabWidgetState extends ConsumerState<_ReviewsTabWidget> {
  String _sortOrder = 'recent';

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(userReviewsStreamProvider(widget.workerId))
        .when(
          data: (reviews) {
            // Calculate Rating Distribution
            int count5 = 0, count4 = 0, count3 = 0, count2 = 0, count1 = 0;
            for (var r in reviews) {
              if (r.rating >= 4.5) {
                count5++;
              } else if (r.rating >= 3.5) {
                count4++;
              } else if (r.rating >= 2.5) {
                count3++;
              } else if (r.rating >= 1.5) {
                count2++;
              } else {
                count1++;
              }
            }
            int total = reviews.isEmpty ? 1 : reviews.length;

            // Sort reviews
            final sortedReviews = List<ReviewModel>.from(reviews);
            if (_sortOrder == 'highest') {
              sortedReviews.sort((a, b) => b.rating.compareTo(a.rating));
            } else if (_sortOrder == 'lowest') {
              sortedReviews.sort((a, b) => a.rating.compareTo(b.rating));
            } else {
              sortedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating Distribution
                Text(
                  context.l10n.publicProfileRatingReviews,
                  style: AppTextStyles.heading3.copyWith(
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          widget.profile.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.headlineLgMobile.copyWith(
                            fontSize: 42,
                            color: context.textColor,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < widget.profile.averageRating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.profile.totalReviews} Reviews',
                          style: AppTextStyles.labelCaption.copyWith(
                            color: context.mutedColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppDimensions.lg),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDistributionBar('5', count5 / total),
                          _buildDistributionBar('4', count4 / total),
                          _buildDistributionBar('3', count3 / total),
                          _buildDistributionBar('2', count2 / total),
                          _buildDistributionBar('1', count1 / total),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),

                // Sort dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.publicProfileRecentReviews,
                        style: AppTextStyles.heading3.copyWith(
                          color: context.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortOrder,
                      dropdownColor: context.surfaceColor,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'recent',
                          child: Text(
                            context.l10n.reviewsSortRecent,
                            style: TextStyle(color: context.textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'highest',
                          child: Text(
                            context.l10n.reviewsSortHighest,
                            style: TextStyle(color: context.textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'lowest',
                          child: Text(
                            context.l10n.reviewsSortLowest,
                            style: TextStyle(color: context.textColor),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortOrder = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),

                if (sortedReviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.lg,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.profileNoReviews,
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedReviews.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final r = sortedReviews[index];
                      return _ReviewCardWidget(review: r);
                    },
                  ),
                const SizedBox(height: AppDimensions.xl),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
            child: SbSkeletonGroup(
              child: Column(children: [SbListRowSkeleton(), SizedBox(height: SbSpace.s3), SbListRowSkeleton()]),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Text(
                context.l10n.profileReviewsError,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildDistributionBar(String label, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.dataNumeric.copyWith(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.borderGray,
              color: AppColors.amber,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCardWidget extends ConsumerStatefulWidget {
  final ReviewModel review;
  const _ReviewCardWidget({required this.review});

  @override
  ConsumerState<_ReviewCardWidget> createState() => _ReviewCardWidgetState();
}

class _ReviewCardWidgetState extends ConsumerState<_ReviewCardWidget> {
  bool _isLoadingVote = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final currentUser = ref.watch(currentUserProvider);
    final hasUpvoted =
        currentUser != null && r.upvoters.contains(currentUser.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  AppAvatar(
                    name: r.reviewerName,
                    imageUrl: r.reviewerPhotoUrl,
                    size: 40,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                r.reviewerName,
                                style: AppTextStyles.bodyStrong.copyWith(
                                  color: context.textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (r.isVerifiedCustomer) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Color(0xFF006622),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < r.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.amber,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.mutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Text(
          r.comment,
          style: AppTextStyles.bodyPrimary.copyWith(color: context.textColor),
        ),

        if (r.photos != null && r.photos!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: r.photos!.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    r.photos![index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            InkWell(
              onTap: _isLoadingVote || currentUser == null
                  ? null
                  : () async {
                      setState(() => _isLoadingVote = true);
                      try {
                        await ref
                            .read(reviewRemoteDataSourceProvider)
                            .updateHelpfulVote(
                              r.id,
                              currentUser.uid,
                              !hasUpvoted,
                            )
                            .timeout(const Duration(seconds: 30));
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            this.context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                      if (mounted) setState(() => _isLoadingVote = false);
                    },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasUpvoted
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : context.surfaceColor,
                  border: Border.all(
                    color: hasUpvoted
                        ? AppColors.primary
                        : AppColors.borderGray,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasUpvoted
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: hasUpvoted
                          ? AppColors.primary
                          : context.mutedColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.reviewsHelpful(r.helpfulVotes),
                      style: AppTextStyles.labelCaption.copyWith(
                        color: hasUpvoted
                            ? AppColors.primary
                            : context.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (r.workerReply != null && r.workerReply!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.reply_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              context.l10n.reviewsReplyFrom(r.revieweeName),
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: context.textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (r.workerReplyAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${r.workerReplyAt!.day}/${r.workerReplyAt!.month}/${r.workerReplyAt!.year}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r.workerReply!,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ] else if (currentUser != null && currentUser.uid == r.revieweeId) ...[
          const SizedBox(height: AppDimensions.md),
          TextButton.icon(
            onPressed: () => _showReplyDialog(context, r.id),
            icon: const Icon(Icons.reply_rounded, size: 18),
            label: Text(context.l10n.reviewsReplyTitle),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  void _showReplyDialog(BuildContext context, String reviewId) {
    final controller = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.l10n.reviewsReplyTitle, style: AppTextStyles.heading3),
              content: TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: context.l10n.reviewsReplyHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
                AppButton(
                  text: context.l10n.reviewsReplySubmit,
                  isLoading: isSubmitting,
                  onPressed: () async {
                    final reply = controller.text.trim();
                    if (reply.isEmpty) return;

                    setState(() => isSubmitting = true);
                    try {
                      await ref
                          .read(reviewRemoteDataSourceProvider)
                          .addWorkerReply(reviewId, reply)
                          .timeout(const Duration(seconds: 30));
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                      if (context.mounted) {
                        setState(() => isSubmitting = false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

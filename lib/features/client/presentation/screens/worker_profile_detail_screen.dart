import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/providers/worker_profile_provider.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:skill_bridge/features/reviews/data/models/review_model.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_chip.dart';

class WorkerProfileDetailScreen extends ConsumerWidget {
  final String workerId;

  const WorkerProfileDetailScreen({
    super.key,
    required this.workerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(workerProfileProvider(workerId));

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: workerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load profile: $err'),
        ),
        data: (worker) {
          if (worker == null || worker.workerProfile == null) {
            return const Center(child: Text('Worker not found.'));
          }

          final profile = worker.workerProfile!;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, worker, profile),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _buildHeaderInfo(worker, profile),
                      const SizedBox(height: AppDimensions.xl),

                      // Quick Stats
                      _buildQuickStats(worker, profile),
                      const SizedBox(height: AppDimensions.xl),

                      // Tabs (About, Gallery, Reviews) using DefaultTabController
                      DefaultTabController(
                        length: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TabBar(
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.onSurfaceVariant,
                              indicatorColor: AppColors.primary,
                              tabs: [
                                Tab(text: 'About'),
                                Tab(text: 'Gallery'),
                                Tab(text: 'Reviews'),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.lg),
                            SizedBox(
                              height: 600, // Fixed height for tab content for now to avoid scrolling issues
                              child: TabBarView(
                                children: [
                                  _buildAboutTab(worker, profile),
                                  _buildGalleryTab(profile),
                                  _ReviewsTabWidget(workerId: worker.uid, profile: profile),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: workerAsync.hasValue && workerAsync.value != null
          ? _buildBottomActionBar(context, workerAsync.value!)
          : null,
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, UserEntity worker, WorkerProfileEntity profile) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () {
            // Share profile logic (Module 1)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality coming soon!')),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            if (profile.coverImage != null && profile.coverImage!.isNotEmpty)
              Image.network(
                profile.coverImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppColors.primary),
              )
            else
              Container(color: AppColors.primary),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            // Profile Photo positioned at bottom left
            Positioned(
              left: AppDimensions.lg,
              bottom: AppDimensions.lg,
              child: AppAvatar(
                name: worker.displayName,
                imageUrl: worker.photoUrl,
                size: 80,
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(UserEntity worker, WorkerProfileEntity profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.displayName,
                    style: AppTextStyles.heading2.copyWith(color: AppColors.onSurface),
                  ).animate().fade(delay: 100.ms),
                  const SizedBox(height: 4),
                  Text(
                    profile.headline,
                    style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary),
                  ).animate().fade(delay: 150.ms),
                ],
              ),
            ),
            if (profile.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006622).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF006622)),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF006622),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${profile.city} (Serves up to ${profile.serviceRadius} km)',
              style: AppTextStyles.bodyPrimary.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ).animate().fade(delay: 250.ms),
      ],
    );
  }

  Widget _buildQuickStats(UserEntity worker, WorkerProfileEntity profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('★ ${profile.averageRating.toStringAsFixed(1)}', '${profile.totalReviews} Reviews'),
        _buildStatItem('${profile.totalJobsCompleted}', 'Jobs Done'),
        _buildStatItem('${profile.experience} Yrs', 'Experience'),
        _buildStatItem('Rs. ${profile.hourlyRate}', 'Starting Price'),
      ],
    ).animate().fade(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(String value, String label) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shadow: AppShadows.level1,
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.onSurface, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(UserEntity worker, WorkerProfileEntity profile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bio', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(profile.bio, style: AppTextStyles.bodyPrimary),
          const SizedBox(height: AppDimensions.xl),
          
          Text('Skills', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.skills.map((s) => AppChip(label: s, isSelected: true)).toList(),
          ),
          const SizedBox(height: AppDimensions.xl),

          Text('Additional Info', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.timer_outlined, 'Response Time', profile.responseTime ?? 'Usually responds quickly'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.language_rounded, 'Languages', profile.languages.isNotEmpty ? profile.languages.join(', ') : 'Urdu, English'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.event_available_rounded, 'Availability', profile.availability == 'available' ? 'Available for work' : 'Busy'),
          const SizedBox(height: AppDimensions.xl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodyStrong),
        Expanded(child: Text(value, style: AppTextStyles.bodyPrimary)),
      ],
    );
  }

  Widget _buildGalleryTab(WorkerProfileEntity profile) {
    final images = [...profile.portfolioImages, ...profile.beforeAfterImages];
    if (images.isEmpty) {
      return const Center(child: Text('No images in gallery.'));
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.borderGray,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        );
      },
    );
  }

  // _buildReviewsTab removed in favor of _ReviewsTabWidget

  Widget _buildBottomActionBar(BuildContext context, UserEntity worker) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: AppShadows.level2,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: AppButton(
                text: 'Contact',
                onPressed: () {
                  // Module 8 Chat or Module 1 simple message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat feature coming soon!')),
                  );
                },
                type: AppButtonType.outline,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'Hire Now',
                onPressed: () {
                  // Will integrate with Module 3 Booking System
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking flow coming in Module 3!')),
                  );
                },
              ),
            ),
          ],
        ),
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
    return ref.watch(userReviewsStreamProvider(widget.workerId)).when(
      data: (reviews) {
        // Calculate Rating Distribution
        int count5 = 0, count4 = 0, count3 = 0, count2 = 0, count1 = 0;
        for (var r in reviews) {
          if (r.rating >= 4.5) count5++;
          else if (r.rating >= 3.5) count4++;
          else if (r.rating >= 2.5) count3++;
          else if (r.rating >= 1.5) count2++;
          else count1++;
        }
        int total = reviews.isEmpty ? 1 : reviews.length; // avoid division by zero

        // Sort reviews
        final sortedReviews = List<ReviewModel>.from(reviews);
        if (_sortOrder == 'highest') {
          sortedReviews.sort((a, b) => b.rating.compareTo(a.rating));
        } else if (_sortOrder == 'lowest') {
          sortedReviews.sort((a, b) => a.rating.compareTo(b.rating));
        } else {
          sortedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating Distribution
              Text('Rating & Reviews', style: AppTextStyles.heading3),
              const SizedBox(height: AppDimensions.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(widget.profile.averageRating.toStringAsFixed(1), style: AppTextStyles.headlineLgMobile.copyWith(fontSize: 48)),
                      Row(
                        children: List.generate(5, (index) => Icon(
                          index < widget.profile.averageRating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.amber,
                          size: 20,
                        )),
                      ),
                      const SizedBox(height: 4),
                      Text('${widget.profile.totalReviews} Reviews', style: AppTextStyles.labelCaption),
                    ],
                  ),
                  const SizedBox(width: AppDimensions.xl),
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
                  Text('Recent Reviews', style: AppTextStyles.heading3),
                  DropdownButton<String>(
                    value: _sortOrder,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                      DropdownMenuItem(value: 'highest', child: Text('Highest Rating')),
                      DropdownMenuItem(value: 'lowest', child: Text('Lowest Rating')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortOrder = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              
              if (sortedReviews.isEmpty) 
                const Center(child: Text('No reviews yet.'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedReviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final r = sortedReviews[index];
                    return _ReviewCardWidget(review: r);
                  },
                ),
                const SizedBox(height: AppDimensions.xl),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading reviews')),
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
    final hasUpvoted = currentUser != null && r.upvoters.contains(currentUser.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppAvatar(name: r.reviewerName, imageUrl: r.reviewerPhotoUrl, size: 40),
                const SizedBox(width: AppDimensions.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.reviewerName, style: AppTextStyles.bodyStrong),
                        if (r.isVerifiedCustomer) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF006622)),
                        ]
                      ],
                    ),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < r.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.amber,
                        size: 14,
                      )),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Text(r.comment, style: AppTextStyles.bodyPrimary),
        
        if (r.photos != null && r.photos!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: r.photos!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
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
              onTap: _isLoadingVote || currentUser == null ? null : () async {
                setState(() => _isLoadingVote = true);
                try {
                  await ref.read(reviewRemoteDataSourceProvider).updateHelpfulVote(r.id, currentUser.uid, !hasUpvoted);
                } catch(e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
                if (mounted) setState(() => _isLoadingVote = false);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasUpvoted ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceWhite,
                  border: Border.all(color: hasUpvoted ? AppColors.primary : AppColors.borderGray),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasUpvoted ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined, 
                      size: 16, 
                      color: hasUpvoted ? AppColors.primary : AppColors.onSurfaceVariant
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${r.helpfulVotes})',
                      style: AppTextStyles.labelCaption.copyWith(
                        color: hasUpvoted ? AppColors.primary : AppColors.onSurfaceVariant,
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
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Reply from ${r.revieweeName}', style: AppTextStyles.bodyStrong),
                      ],
                    ),
                    if (r.workerReplyAt != null)
                      Text(
                        '${r.workerReplyAt!.day}/${r.workerReplyAt!.month}/${r.workerReplyAt!.year}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(r.workerReply!, style: AppTextStyles.bodyPrimary),
              ],
            ),
          ),
        ] else if (currentUser != null && currentUser.uid == r.revieweeId) ...[
          const SizedBox(height: AppDimensions.md),
          TextButton.icon(
            onPressed: () => _showReplyDialog(context, r.id),
            icon: const Icon(Icons.reply_rounded, size: 18),
            label: const Text('Reply to Review'),
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
              title: Text('Reply to Review', style: AppTextStyles.heading3),
              content: TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your response here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  text: 'Submit Reply',
                  isLoading: isSubmitting,
                  onPressed: () async {
                    final reply = controller.text.trim();
                    if (reply.isEmpty) return;

                    setState(() => isSubmitting = true);
                    try {
                      await ref.read(reviewRemoteDataSourceProvider).addWorkerReply(reviewId, reply);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                      setState(() => isSubmitting = false);
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
}


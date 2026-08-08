import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_chip.dart';

/// Guild Modernist Worker Profile Screen (b2_worker_profile)
class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Worker Profile • کاریگر پروفائل',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.onSurface),
            onPressed: () => context.push(RouteNames.workerSettingsPath),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppDimensions.sm),
                  AppAvatar(
                    name: user.displayName,
                    imageUrl: user.photoUrl,
                    size: 100,
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    user.displayName,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ).animate().fade(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Professional Electrician • الیکٹریشن',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.primary,
                    ),
                  ).animate().fade(delay: 150.ms, duration: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    '${user.city ?? 'Lahore, Pakistan'} • ★ ${user.rating.toStringAsFixed(1)} (${user.totalReviews} Reviews)',
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ).animate().fade(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF006622)),
                              SizedBox(width: 8),
                              Text('NADRA Verified • تصدیق شدہ شناخت'),
                            ],
                          ),
                          content: const Text(
                            'This worker\'s National Identity Card (CNIC) and live biometric selfie have been verified against NADRA records for in-home safety and trust.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006622).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF006622), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF006622)),
                          const SizedBox(width: 6),
                          Text(
                            'NADRA CNIC Verified • تصدیق شدہ',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFF006622),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 220.ms, duration: 400.ms),
                  const SizedBox(height: AppDimensions.xl),

                  // ── Hourly Rate Card (Navy Theme + JetBrains Mono) ────────
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      boxShadow: AppShadows.level2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hourly Rate • فی گھنٹہ ریٹ',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.surfaceWhite,
                          ),
                        ),
                        Text(
                          'Rs. 800 / hr',
                          style: AppTextStyles.dataNumericLg.copyWith(
                            color: AppColors.amber,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 250.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppDimensions.lg),

                  // ── Skills Card ───────────────────────────────────────────
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    shadow: AppShadows.level2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skills & Expertise • مہارتیں',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppChip(label: 'Wiring', isSelected: true),
                            AppChip(label: 'Circuit Repair', isSelected: true),
                            AppChip(label: 'Generator Setup', isSelected: true),
                            AppChip(label: 'Solar Inverter', isSelected: true),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppDimensions.lg),

                  // ── Details Card (Languages & Response Time) ───────────────
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    shadow: AppShadows.level2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Details • اضافی تفصیلات',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        if (user.workerProfile?.languages != null &&
                            user.workerProfile!.languages.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.language_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Languages: ${user.workerProfile!.languages.join(', ')}',
                                  style: AppTextStyles.bodyPrimary.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.timer_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Response Time: ${user.workerProfile?.responseTime ?? 'Unknown'}',
                                style: AppTextStyles.bodyPrimary.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 310.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppDimensions.lg),

                  // ── Reviews Card ──────────────────────────────────────────
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    shadow: AppShadows.level2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Reviews • حالیہ جائزے',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        ref.watch(userReviewsStreamProvider(user.uid)).when(
                              data: (reviews) {
                                if (reviews.isEmpty) {
                                  return Text(
                                    'No reviews yet • ابھی تک کوئی جائزہ نہیں',
                                    style: AppTextStyles.bodyPrimary.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: reviews.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    final r = reviews[index];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              r.reviewerName,
                                              style: AppTextStyles.bodyStrong
                                                  .copyWith(
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                            Text(
                                              '★ ${r.rating.toStringAsFixed(1)}',
                                              style: AppTextStyles.bodyStrong
                                                  .copyWith(
                                                color: AppColors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          r.comment,
                                          style: AppTextStyles.bodyPrimary
                                              .copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, _) => Text(
                                'Could not load reviews • جائزے لوڈ نہیں ہو سکے',
                                style: AppTextStyles.bodyPrimary.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ).animate().fade(delay: 325.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppDimensions.space48),

                  // ── Edit Profile Button ───────────────────────────────────
                  AppButton(
                    text: 'Edit Worker Profile • پروفائل میں ترمیم کریں',
                    onPressed: () {
                      context.push(RouteNames.workerProfileSetupPath);
                    },
                    width: double.infinity,
                  ).animate().fade(delay: 350.ms, duration: 500.ms),
                ],
              ),
            ),
    );
  }
}

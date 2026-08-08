import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/utils/formatters.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';

/// Guild Modernist Signature Component — Job Card (Job Listing Card)
/// Features:
/// - 16px radius, white surface, Level 2 (2dp) shadow
/// - 4px vertical left accent bar color-coded by trade category
/// - Blue-tint category pill
/// - JetBrains Mono typography for PKR budget and ratings
class JobCard extends StatelessWidget {
  final String title;
  final String category;
  final double budgetPkr;
  final String? budgetType; // e.g. 'Hourly' or 'Fixed'
  final String? locationText;
  final String clientName;
  final String? clientAvatarUrl;
  final double? clientRating;
  final DateTime? postedAt;
  final bool isUrgent;
  final VoidCallback? onTap;
  final VoidCallback? onApplyTap;
  final String? applyButtonLabel;

  const JobCard({
    super.key,
    required this.title,
    required this.category,
    required this.budgetPkr,
    this.budgetType = 'Fixed',
    this.locationText,
    required this.clientName,
    this.clientAvatarUrl,
    this.clientRating,
    this.postedAt,
    this.isUrgent = false,
    this.onTap,
    this.onApplyTap,
    this.applyButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // 6% alpha
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x1A000000), // 10% alpha
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4px Left Accent Bar
                  Container(
                    width: 4,
                    color: accentColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Category Pill & Urgent / Posted Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blueTint,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: AppTextStyles.labelCaption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isUrgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                  ),
                                  child: Text(
                                    'URGENT • فوری',
                                    style: AppTextStyles.labelCaption.copyWith(
                                      color: AppColors.onErrorContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else if (postedAt != null)
                                Text(
                                  Formatters.formatRelativeTime(postedAt!),
                                  style: AppTextStyles.labelCaption.copyWith(
                                    color: AppColors.outline,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          // Job Title
                          Text(
                            title,
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.onSurface,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (locationText != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.outline,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    locationText!,
                                    style: AppTextStyles.labelCaption.copyWith(
                                      color: AppColors.outline,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppDimensions.md),
                          // Divider
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.outlineVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          // Client Info + Budget Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Client Avatar & Name
                              Expanded(
                                child: Row(
                                  children: [
                                    AppAvatar(
                                      imageUrl: clientAvatarUrl,
                                      name: clientName,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientName,
                                            style: AppTextStyles.bodyStrong.copyWith(
                                              fontSize: 12,
                                              color: AppColors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (clientRating != null)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  size: 12,
                                                  color: AppColors.amberWarm,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  clientRating!.toStringAsFixed(1),
                                                  style: AppTextStyles.dataNumeric.copyWith(
                                                    fontSize: 11,
                                                    color: AppColors.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Budget in PKR (JetBrains Mono)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        Formatters.formatPkr(budgetPkr),
                                        style: AppTextStyles.dataNumeric.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (budgetType == 'Hourly')
                                        Text(
                                          '/hr',
                                          style: AppTextStyles.labelCaption.copyWith(
                                            color: AppColors.outline,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    budgetType ?? 'Fixed Budget',
                                    style: AppTextStyles.labelCaption.copyWith(
                                      color: AppColors.outline,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      ),
    );
  }
}

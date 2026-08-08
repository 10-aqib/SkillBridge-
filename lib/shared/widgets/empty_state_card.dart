import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';

/// Dedicated Single-Language Empty State Card.
/// Displays ONLY English when English is selected, or ONLY Urdu when Urdu is selected.
class EmptyStateCard extends StatelessWidget {
  final String titleEn;
  final String titleUr;
  final String subtitleEn;
  final String subtitleUr;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabelEn;
  final String? actionLabelUr;

  const EmptyStateCard({
    super.key,
    required this.titleEn,
    required this.titleUr,
    required this.subtitleEn,
    required this.subtitleUr,
    this.icon = Icons.inbox_outlined,
    this.onActionPressed,
    this.actionLabelEn,
    this.actionLabelUr,
  });

  @override
  Widget build(BuildContext context) {
    final title = AppL10n.select(context, en: titleEn, ur: titleUr);
    final subtitle = AppL10n.select(context, en: subtitleEn, ur: subtitleUr);
    final actionLabel =
        (actionLabelEn != null && actionLabelUr != null)
            ? AppL10n.select(
              context,
              en: actionLabelEn!,
              ur: actionLabelUr!,
            )
            : null;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xl,
          vertical: AppDimensions.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: AppColors.darkLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44.0,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(color: AppColors.darkText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.darkMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: AppDimensions.xl),
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xl,
                    vertical: AppDimensions.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                child: Text(actionLabel, style: AppTextStyles.bodyStrong),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

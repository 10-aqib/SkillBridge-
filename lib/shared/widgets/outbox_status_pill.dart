import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';

/// Floating glassmorphic pill showing queued offline actions in single-language format.
class OutboxStatusPill extends StatelessWidget {
  final int pendingCount;
  final VoidCallback? onSyncTap;

  const OutboxStatusPill({
    super.key,
    required this.pendingCount,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) {
      return const SizedBox.shrink();
    }

    final statusText = AppL10n.select(
      context,
      en: 'Offline Mode: $pendingCount pending action${pendingCount > 1 ? 's' : ''} queued',
      ur: 'آف لائن موڈ: $pendingCount ایکشن قطار میں ہیں',
    );

    final syncText = AppL10n.select(
      context,
      en: 'Sync Now',
      ur: 'ابھی سنک کریں',
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: AppColors.amberWarm.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.amberWarm,
            size: 18.0,
          ),
          const SizedBox(width: AppDimensions.sm),
          Text(
            statusText,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.darkText,
            ),
          ),
          if (onSyncTap != null) ...[
            const SizedBox(width: AppDimensions.md),
            GestureDetector(
              onTap: onSyncTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amberWarm.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  syncText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.amberWarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

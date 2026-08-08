import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

/// Guild Modernist Status Pill Badge
/// Uses Skill-Green (#005438) for Verified/Available, amberWarm for Busy, errorRed for Urgent
class AppBadge extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });

  // Verified Pro Badge (Skill-Green)
  factory AppBadge.verified(BuildContext context) {
    return AppBadge(
      text: 'Verified • تصدیق شدہ',
      icon: Icons.verified,
      textColor: AppColors.tertiary,
      backgroundColor: AppColors.tertiary.withValues(alpha: 0.12),
    );
  }

  // Urgent Job Badge
  factory AppBadge.urgent(BuildContext context) {
    return AppBadge(
      text: 'URGENT • فوری',
      icon: Icons.bolt,
      textColor: AppColors.errorRed,
      backgroundColor: AppColors.errorContainer,
    );
  }

  // Available Status Badge
  factory AppBadge.available() {
    return AppBadge(
      text: 'Available • دستیاب',
      icon: Icons.circle,
      textColor: AppColors.tertiary,
      backgroundColor: AppColors.tertiary.withValues(alpha: 0.12),
    );
  }

  // Busy Status Badge
  factory AppBadge.busy() {
    return AppBadge(
      text: 'Busy',
      icon: Icons.circle,
      textColor: AppColors.amberWarm,
      backgroundColor: AppColors.amberWarm.withValues(alpha: 0.15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.labelCaption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

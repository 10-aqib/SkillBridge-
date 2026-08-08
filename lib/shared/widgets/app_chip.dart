import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

/// Guild Modernist Category Filter Chip
/// Selected: Primary Blue (#003fb1) with white text
/// Unselected: Blue-tint background (#EFF6FF) with Primary text (#003fb1)
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      avatar: avatar,
      showCheckmark: false,
      labelStyle: AppTextStyles.labelCaption.copyWith(
        color: isSelected ? AppColors.onPrimary : AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      backgroundColor: AppColors.blueTint,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
    );
  }
}

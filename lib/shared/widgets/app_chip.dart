import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

/// Category filter chip on SkillBridge tokens (light and dark).
/// Selected: primary fill with on-primary text.
/// Unselected: primary-subtle fill with on-primary-subtle text.
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
    final c = context.sb;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      avatar: avatar,
      showCheckmark: false,
      labelStyle: AppTextStyles.labelCaption.copyWith(
        color: isSelected ? c.onPrimary : c.onPrimarySubtle,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      backgroundColor: c.primarySubtle,
      selectedColor: c.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        side: BorderSide(
          color: isSelected ? c.primary : c.primary.withValues(alpha: 0.3),
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

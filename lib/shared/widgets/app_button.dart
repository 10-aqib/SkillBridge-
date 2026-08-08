import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

enum AppButtonType { solid, outline, text }

/// Guild Modernist Button Component
/// Supports primary (#003fb1), secondary outline, and success (#005438) variants
/// 52px default height, 12px radius, Inter bodyStrong typography
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool isSmall;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.solid,
    this.isLoading = false,
    this.isSmall = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultBg = type == AppButtonType.solid
        ? (backgroundColor ?? theme.colorScheme.primary)
        : Colors.transparent;

    final defaultTextCol = type == AppButtonType.solid
        ? (textColor ?? theme.colorScheme.onPrimary)
        : (textColor ?? theme.colorScheme.primary);

    final border = type == AppButtonType.outline
        ? BorderSide(color: backgroundColor ?? AppColors.primary, width: 1.5)
        : BorderSide.none;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isSmall ? AppDimensions.radiusSm : AppDimensions.radiusMd),
    );

    final buttonHeight = isSmall ? 40.0 : 52.0; // 52px standard touch target per Guild Modernist
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 14)
        : const EdgeInsets.symmetric(horizontal: AppDimensions.md);

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: type == AppButtonType.solid
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: defaultBg,
                foregroundColor: defaultTextCol,
                shape: shape,
                elevation: 1, // Subtle Level 2 elevation
                padding: padding,
                minimumSize: Size(0, buttonHeight),
              ),
              child: _buildChild(defaultTextCol),
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: defaultTextCol,
                side: border,
                shape: shape,
                padding: padding,
                minimumSize: Size(0, buttonHeight),
              ),
              child: _buildChild(defaultTextCol),
            ),
    );
  }

  Widget _buildChild(Color currentTextColor) {
    if (isLoading) {
      return SizedBox(
        width: isSmall ? 16 : 20,
        height: isSmall ? 16 : 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(currentTextColor),
        ),
      );
    }

    final textStyle = isSmall
        ? AppTextStyles.labelCaption.copyWith(color: currentTextColor, fontWeight: FontWeight.w600, fontSize: 13)
        : AppTextStyles.bodyStrong.copyWith(color: currentTextColor);

    final textWidget = Text(
      text,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 16 : 18, color: currentTextColor),
          SizedBox(width: isSmall ? 6 : AppDimensions.sm),
          Flexible(child: textWidget),
        ],
      );
    }

    return textWidget;
  }
}

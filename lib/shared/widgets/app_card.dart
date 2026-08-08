import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';

/// Guild Modernist Level 2 Surface Card
/// Features 16px radius, white surface, Level 2 (2dp) shadow, and optional 4px left accent bar
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? radius;
  final BorderSide? border;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final Color? leftAccentColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.radius,
    this.border,
    this.shadow,
    this.onTap,
    this.leftAccentColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = widget.color ?? (isDark ? AppColors.darkCard : AppColors.surfaceWhite);
    final cardRadius = widget.radius ?? AppDimensions.radiusLg;

    final content = Container(
      padding: widget.padding ?? const EdgeInsets.all(AppDimensions.md),
      child: widget.child,
    );

    final cardWidget = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(cardRadius),
        border: widget.border != null
            ? Border.fromBorderSide(widget.border!)
            : Border.all(
                color: isDark
                    ? AppColors.darkLine
                    : AppColors.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
        boxShadow: widget.shadow ?? AppShadows.level2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: widget.leftAccentColor != null
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      color: widget.leftAccentColor,
                    ),
                    Expanded(
                      child: _buildTouchable(cardRadius, content),
                    ),
                  ],
                ),
              )
            : _buildTouchable(cardRadius, content),
      ),
    );

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutQuad,
      child: cardWidget,
    );
  }

  Widget _buildTouchable(double cardRadius, Widget content) {
    if (widget.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(cardRadius),
          child: content,
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: content,
    );
  }
}

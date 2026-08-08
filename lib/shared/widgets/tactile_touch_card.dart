import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';

/// Guild Modernist Tactile Touch Wrapper.
/// Adds a responsive physical scale-on-press micro-animation and
/// tactile haptic impact to cards, category chips, and buttons.
class TactileTouchCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownTo;
  final double borderRadius;
  final bool enableHaptics;

  const TactileTouchCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownTo = 0.97,
    this.borderRadius = AppDimensions.radiusLg,
    this.enableHaptics = true,
  });

  @override
  State<TactileTouchCard> createState() => _TactileTouchCardState();
}

class _TactileTouchCardState extends State<TactileTouchCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? widget.scaleDownTo : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}

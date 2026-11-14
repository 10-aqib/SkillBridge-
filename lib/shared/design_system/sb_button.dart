import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';

/// Button hierarchy. Use one [primary] per decision area.
enum SbButtonVariant {
  /// The main action of the area (Post job, Send proposal, Book).
  primary,

  /// Alternative to the primary action (Message, Save draft).
  secondary,

  /// Low-emphasis action (See all, Cancel, Skip).
  quiet,

  /// Irreversible or harmful action. Always behind a confirmation.
  destructive,
}

enum SbButtonSize {
  /// 48 dp — default on mobile.
  regular,

  /// 40 dp — dense rows and secondary toolbars only.
  compact,
}

/// SkillBridge button. Handles loading (keeps width, announces busy), disabled
/// and icon placement (mirrors automatically in RTL).
class SbButton extends StatelessWidget {
  const SbButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SbButtonVariant.primary,
    this.size = SbButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
    this.loadingSemanticLabel,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final SbButtonVariant variant;
  final SbButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;

  /// Fill the available width (sticky bottom actions, forms).
  final bool expand;
  final String? semanticLabel;

  /// Read out while [isLoading], e.g. "Sending proposal".
  final String? loadingSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final height = size == SbButtonSize.regular ? SbTarget.mobile : SbTarget.compact;
    final enabled = onPressed != null && !isLoading;

    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      SbButtonVariant.primary => (c.primary, c.onPrimary, BorderSide.none),
      SbButtonVariant.secondary => (c.surface, c.primary, BorderSide(color: c.borderStrong)),
      SbButtonVariant.quiet => (Colors.transparent, c.primary, BorderSide.none),
      SbButtonVariant.destructive => (c.error, c.onError, BorderSide.none),
    };

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(height, height)),
      fixedSize: expand ? WidgetStatePropertyAll(Size.fromHeight(height)) : null,
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: variant == SbButtonVariant.quiet
              ? SbSpace.s3
              : (size == SbButtonSize.regular ? SbSpace.s5 : SbSpace.s4),
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(SbRadius.control))),
      ),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) && side != BorderSide.none
            ? BorderSide(color: c.border)
            : side,
      ),
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled) && !isLoading) {
          return variant == SbButtonVariant.quiet ? Colors.transparent : c.surfaceSunken;
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) && !isLoading ? c.textDisabled : fg,
      ),
      overlayColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.pressed)) return fg.withValues(alpha: 0.14);
        if (s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)) {
          return fg.withValues(alpha: 0.08);
        }
        return null;
      }),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 15),
      ),
      animationDuration: SbMotion.of(context, SbMotion.fast),
    );

    final iconSize = size == SbButtonSize.regular ? 20.0 : 18.0;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: iconSize), const SizedBox(width: SbSpace.s2)],
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (trailingIcon != null) ...[
          const SizedBox(width: SbSpace.s2),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );

    // While loading, keep the label's footprint so the button does not jump.
    final child = isLoading
        ? Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0, child: content),
              SizedBox.square(
                dimension: iconSize,
                child: CircularProgressIndicator(strokeWidth: 2.25, color: fg),
              ),
            ],
          )
        : content;

    // Busy state is announced through the label, not by a spinner alone.
    final a11yLabel = isLoading && loadingSemanticLabel != null ? loadingSemanticLabel : semanticLabel;
    return Semantics(
      button: true,
      enabled: enabled,
      label: a11yLabel,
      excludeSemantics: a11yLabel != null,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/shared/design_system/sb_button.dart';

enum AppButtonType { solid, outline, text }

/// Legacy button API, rendered by [SbButton].
///
/// solid → primary, outline → secondary, text → quiet. An error-coloured
/// background becomes the destructive variant. Any other custom colour is
/// applied through a scoped token override so it still gets SbButton's sizing,
/// loading and accessibility behaviour.
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
    final sb = context.sb;
    final scheme = Theme.of(context).colorScheme;
    final isErrorColour = backgroundColor != null &&
        (backgroundColor == scheme.error || backgroundColor == sb.error);

    var variant = switch (type) {
      AppButtonType.solid => SbButtonVariant.primary,
      AppButtonType.outline => SbButtonVariant.secondary,
      AppButtonType.text => SbButtonVariant.quiet,
    };
    if (type == AppButtonType.solid && isErrorColour) {
      variant = SbButtonVariant.destructive;
    }

    final expand = width == double.infinity;
    Widget button = SbButton(
      label: text,
      onPressed: onPressed,
      variant: variant,
      size: isSmall ? SbButtonSize.compact : SbButtonSize.regular,
      icon: icon,
      isLoading: isLoading,
      expand: expand,
    );

    // Custom colours (not the error case): override the tokens SbButton reads.
    final customColours = !isErrorColour && (backgroundColor != null || textColor != null);
    if (customColours) {
      final theme = Theme.of(context);
      final overridden = type == AppButtonType.solid
          ? sb.copyWith(primary: backgroundColor, onPrimary: textColor)
          : sb.copyWith(primary: textColor ?? backgroundColor);
      button = Theme(
        data: theme.copyWith(
          extensions: [
            ...theme.extensions.values.where((e) => e is! SbColors),
            overridden,
          ],
        ),
        child: button,
      );
    }

    if (width != null && !expand) {
      return SizedBox(width: width, child: button);
    }
    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

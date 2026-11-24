import 'package:flutter/material.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Colours of the worker home screen and its earnings chart, following the
/// app's light/dark setting (the screen used to be always dark).
///
/// Read it in each `build` with `WorkerPalette.of(context)`, so the screen
/// repaints when the theme changes.
class WorkerPalette {
  const WorkerPalette({
    required this.bg,
    required this.card,
    required this.surface2,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.accent,
    required this.success,
    required this.danger,
  });

  /// Page background.
  final Color bg;

  /// Cards.
  final Color card;

  /// Recessed areas inside cards (chips, icon wells).
  final Color surface2;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  /// Buttons, links and highlights (white text sits on it).
  final Color accent;
  final Color success;
  final Color danger;

  static WorkerPalette of(BuildContext context) {
    final sb = context.sb;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return WorkerPalette(
      bg: sb.canvas,
      card: sb.surface,
      surface2: dark ? const Color(0xFF1C2631) : sb.surfaceSunken,
      textPrimary: sb.text,
      textSecondary: sb.textSecondary,
      border: sb.border,
      accent: dark ? const Color(0xFF4778E8) : const Color(0xFF2563EB),
      success: sb.success,
      danger: const Color(0xFFEF5350),
    );
  }
}

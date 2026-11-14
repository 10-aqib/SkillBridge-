import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/shared/design_system/sb_button.dart';

/// Confirmation for consequential actions (hire, decline, cancel contract,
/// report). States what will happen in [message]; the confirm label names the
/// action ("Hire Ahmed"), never just "OK".
///
/// Returns true only when the user confirms.
Future<bool> showSbConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
  Widget? details,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      final edge = SbLayout.edge(ctx);
      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(edge, 0, edge, SbSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: t.titleLarge)),
            const SizedBox(height: SbSpace.s2),
            Text(message, style: t.bodyLarge!.copyWith(color: ctx.sb.textSecondary)),
            if (details != null) ...[const SizedBox(height: SbSpace.s4), details],
            const SizedBox(height: SbSpace.s6),
            SbButton(
              label: confirmLabel,
              expand: true,
              variant: destructive ? SbButtonVariant.destructive : SbButtonVariant.primary,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: SbSpace.s2),
            SbButton(
              label: cancelLabel,
              expand: true,
              variant: SbButtonVariant.quiet,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

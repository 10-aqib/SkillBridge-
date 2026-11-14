import 'package:flutter/material.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/shared/design_system/sb_state_view.dart';

/// Single-language empty state (shows English OR Urdu, never both).
///
/// Previously hardcoded dark colours, so it rendered dark in light mode. Now
/// rendered by [SbStateView], which follows the active theme.
class EmptyStateCard extends StatelessWidget {
  final String titleEn;
  final String titleUr;
  final String subtitleEn;
  final String subtitleUr;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabelEn;
  final String? actionLabelUr;

  const EmptyStateCard({
    super.key,
    required this.titleEn,
    required this.titleUr,
    required this.subtitleEn,
    required this.subtitleUr,
    this.icon = Icons.inbox_outlined,
    this.onActionPressed,
    this.actionLabelEn,
    this.actionLabelUr,
  });

  @override
  Widget build(BuildContext context) {
    final actionLabel = (actionLabelEn != null && actionLabelUr != null)
        ? AppL10n.select(context, en: actionLabelEn!, ur: actionLabelUr!)
        : null;

    return Center(
      child: SingleChildScrollView(
        child: SbStateView(
          kind: SbStateKind.empty,
          title: AppL10n.select(context, en: titleEn, ur: titleUr),
          message: AppL10n.select(context, en: subtitleEn, ur: subtitleUr),
          icon: icon,
          actionLabel: actionLabel,
          onAction: onActionPressed,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skill_bridge/shared/design_system/sb_state_view.dart';

/// Legacy empty-state API, rendered by [SbStateView] (empty kind).
/// Same widget as [EmptyStateCard]; both now share one implementation.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: SbStateView(
          kind: SbStateKind.empty,
          title: title,
          message: description,
          icon: icon,
          actionLabel: actionLabel,
          onAction: onActionPressed,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/sb_state_view.dart';

/// Legacy error-state API, rendered by [SbStateView] (error kind): distinct
/// icon and tone from empty states, announced as a live region, retry kept.
class AppErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Existing ARB keys (English + Urdu); falls back if no localizations above.
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: SbStateView(
          kind: SbStateKind.error,
          title: l10n?.somethingWentWrong ?? 'Something went wrong',
          message: errorMessage,
          actionLabel: onRetry != null ? (l10n?.tryAgain ?? 'Try Again') : null,
          onAction: onRetry,
        ),
      ),
    );
  }
}

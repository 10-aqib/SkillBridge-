import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/shared/design_system/sb_button.dart';

/// Which non-content state a region is in. Each has a distinct icon and tone so
/// "nothing here" is never confused with "could not load".
enum SbStateKind {
  /// Loaded successfully, zero records.
  empty,

  /// Request failed. Show a retry; never the raw exception.
  error,

  /// No connection. Cached data (if any) stays visible above this.
  offline,

  /// Location / notification / camera permission missing.
  permission,

  /// Domain event confirmed by the server.
  success,
}

/// Full-region state for lists and pages: empty, error, offline, permission,
/// success. One clear next action at most.
class SbStateView extends StatelessWidget {
  const SbStateView({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.compact = false,
  });

  final SbStateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  /// Inline inside a section (home preview) rather than filling a page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    final (IconData defaultIcon, SbTone tone) = switch (kind) {
      SbStateKind.empty => (Icons.inbox_outlined, SbTone.neutral),
      SbStateKind.error => (Icons.error_outline_rounded, SbTone.error),
      SbStateKind.offline => (Icons.cloud_off_rounded, SbTone.neutral),
      SbStateKind.permission => (Icons.lock_outline_rounded, SbTone.info),
      SbStateKind.success => (Icons.check_circle_outline_rounded, SbTone.success),
    };
    final pair = c.tone(tone);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 48 : 64,
          height: compact ? 48 : 64,
          decoration: BoxDecoration(color: pair.background, shape: BoxShape.circle),
          child: Icon(icon ?? defaultIcon, size: compact ? 24 : 30, color: pair.foreground),
        ),
        SizedBox(height: compact ? SbSpace.s3 : SbSpace.s4),
        Text(
          title,
          style: compact ? t.titleSmall : t.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          const SizedBox(height: SbSpace.s1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message!,
              style: t.bodyMedium!.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: compact ? SbSpace.s3 : SbSpace.s5),
          SbButton(
            label: actionLabel!,
            onPressed: onAction,
            variant: kind == SbStateKind.empty ? SbButtonVariant.primary : SbButtonVariant.secondary,
            icon: kind == SbStateKind.error || kind == SbStateKind.offline
                ? Icons.refresh_rounded
                : null,
          ),
        ],
      ],
    );

    return Semantics(
      liveRegion: kind == SbStateKind.error || kind == SbStateKind.success,
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SbLayout.edge(context),
          vertical: compact ? SbSpace.s5 : SbSpace.s10,
        ),
        child: Center(child: body),
      ),
    );
  }
}

/// One-line banner above content: offline with cached data, "queued, will
/// send when online", stale data, or a non-blocking error.
class SbInlineBanner extends StatelessWidget {
  const SbInlineBanner({
    super.key,
    required this.message,
    this.tone = SbTone.info,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final SbTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final pair = context.sb.tone(tone);
    final t = Theme.of(context).textTheme;
    final defaultIcon = switch (tone) {
      SbTone.warning => Icons.cloud_off_rounded,
      SbTone.error => Icons.error_outline_rounded,
      SbTone.success => Icons.check_circle_outline_rounded,
      _ => Icons.info_outline_rounded,
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(SbSpace.s3, SbSpace.s2, SbSpace.s1, SbSpace.s2),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(SbRadius.control),
        ),
        child: Row(
          children: [
            Icon(icon ?? defaultIcon, size: 20, color: pair.foreground),
            const SizedBox(width: SbSpace.s2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SbSpace.s1),
                child: Text(message, style: t.bodyMedium!.copyWith(color: pair.foreground)),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: pair.foreground),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Offline messages are plain black text (white in dark mode, where black
/// would be unreadable).
Color offlineInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

/// "You're offline" in plain text (the app's normal text colour: black in
/// light mode, white in dark), with a small cloud icon. No coloured box: the
/// owner asked for a simple message instead of the yellow warning bar.
/// [onSurface] gives it a plain surface card, for use over a map or photo.
class SbOfflineNote extends StatelessWidget {
  const SbOfflineNote({super.key, required this.message, this.onSurface = false});

  final String message;
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    final row = Row(children: [
      Icon(Icons.cloud_off_rounded, size: 18, color: offlineInk(context)),
      const SizedBox(width: SbSpace.s2),
      Expanded(child: Text(message, style: t.bodyMedium!.copyWith(color: offlineInk(context)))),
    ]);
    return Semantics(
      liveRegion: true,
      container: true,
      child: onSurface
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3, vertical: SbSpace.s2),
              decoration: BoxDecoration(
                color: sb.surface,
                borderRadius: BorderRadius.circular(SbRadius.control),
                border: Border.all(color: sb.border),
              ),
              child: row,
            )
          : Padding(padding: const EdgeInsets.symmetric(vertical: SbSpace.s1), child: row),
    );
  }
}

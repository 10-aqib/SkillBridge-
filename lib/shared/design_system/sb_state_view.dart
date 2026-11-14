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
      SbStateKind.offline => (Icons.cloud_off_rounded, SbTone.warning),
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

/// Skeleton block that matches the shape of the content it stands in for.
/// Pulses gently; static when reduced motion is on.
class SbSkeleton extends StatefulWidget {
  const SbSkeleton({super.key, this.width, this.height = 14, this.radius = SbRadius.xs, this.circle = false});

  const SbSkeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = SbRadius.full,
        circle = true;

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<SbSkeleton> createState() => _SbSkeletonState();
}

class _SbSkeletonState extends State<SbSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.55).animate(_ctrl),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: c.surfaceSunken,
            borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching [SbWorkerCard] / [SbJobCard] rows. Wrap a list of these in
/// a `Semantics(label: l10n.loading)` at the list level.
class SbListRowSkeleton extends StatelessWidget {
  const SbListRowSkeleton({super.key, this.leadingCircle = true});

  final bool leadingCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(
        color: context.sb.surface,
        borderRadius: BorderRadius.circular(SbRadius.card),
        border: Border.all(color: context.sb.border),
      ),
      child: Row(
        children: [
          leadingCircle
              ? const SbSkeleton.circle(size: 52)
              : const SbSkeleton(width: 44, height: 44, radius: SbRadius.control),
          const SizedBox(width: SbSpace.s3),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SbSkeleton(width: 160, height: 16),
                SizedBox(height: SbSpace.s2),
                SbSkeleton(width: 110, height: 12),
                SizedBox(height: SbSpace.s3),
                SbSkeleton(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

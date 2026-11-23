import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';

// Loading placeholders that follow four rules:
//  1. Show the shape of what's coming instead of a spinner.
//  2. Match the real content: circle = avatar, short bar = name,
//     long lines = text, block = image.
//  3. One shimmer sweeps across the whole placeholder in reading direction
//     (left to right; right to left in Urdu). Every block shares it, so it
//     reads as one wave rather than many separate pulses.
//  4. Same slot, zero jump: placeholders take the size of the real content,
//     and [SbLoadSwitcher] cross-fades to it.
// With reduced motion the shimmer stops and placeholders are still.

/// Shares one shimmer animation with every [SbSkeleton] below it.
class SbShimmer extends StatefulWidget {
  const SbShimmer({super.key, required this.child});

  final Widget child;

  static const Duration period = Duration(milliseconds: 1500);

  static SbShimmerState? maybeOf(BuildContext context) => context.findAncestorStateOfType<SbShimmerState>();

  @override
  State<SbShimmer> createState() => SbShimmerState();
}

class SbShimmerState extends State<SbShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: SbShimmer.period);

  /// Repaints the blocks while the shimmer moves.
  Listenable get changes => _ctrl;

  /// 0..1 position of the highlight, or null when still (reduced motion).
  double? get progress => _ctrl.isAnimating ? _ctrl.value : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// This shimmer's box, for lining blocks up with one shared gradient.
  RenderBox? get box {
    final ro = context.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro : null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One placeholder block. Inside an [SbShimmer] it shares that shimmer;
/// on its own it brings its own.
class SbSkeleton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final block = _SkeletonBlock(width: width, height: height, radius: radius, circle: circle);
    return SbShimmer.maybeOf(context) == null ? SbShimmer(child: block) : block;
  }
}

class _SkeletonBlock extends StatefulWidget {
  const _SkeletonBlock({required this.width, required this.height, required this.radius, required this.circle});

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock> {
  @override
  Widget build(BuildContext context) {
    final shimmer = SbShimmer.maybeOf(context)!;
    final c = context.sb;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = c.surfaceSunken;
    final highlight = Color.lerp(base, Colors.white, dark ? 0.07 : 0.7)!;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        // Like an empty Container: fills the width it's given (none if the
        // width is unbounded) unless a width is set.
        child: LimitedBox(
          maxWidth: 0,
          maxHeight: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: CustomPaint(
              painter: _ShimmerPainter(
                shimmer: shimmer,
                block: () => context.findRenderObject() as RenderBox?,
                base: base,
                highlight: highlight,
                rtl: Directionality.of(context) == TextDirection.rtl,
                radius: widget.circle ? null : widget.radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.shimmer,
    required this.block,
    required this.base,
    required this.highlight,
    required this.rtl,
    required this.radius,
  }) : super(repaint: shimmer.changes);

  final SbShimmerState shimmer;
  final RenderBox? Function() block;
  final Color base;
  final Color highlight;
  final bool rtl;

  /// Null draws a circle.
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..isAntiAlias = true;
    final progress = shimmer.progress;
    final area = shimmer.box;
    final me = block();
    if (progress == null || area == null || me == null || !me.attached) {
      paint.color = base;
    } else {
      // The gradient spans the whole shimmer area, so neighbouring blocks show
      // consecutive slices of the same wave.
      final origin = me.localToGlobal(Offset.zero, ancestor: area);
      final w = area.size.width;
      final band = w * 0.6;
      // Travels from fully before the area to fully past it.
      final t = rtl ? 1 - progress : progress;
      final centre = -band + (w + 2 * band) * t;
      paint.shader = LinearGradient(
        colors: [base, highlight, base],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(centre - band / 2 - origin.dx, -origin.dy, band, area.size.height));
    }
    if (radius == null) {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius!)), paint);
    }
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.base != base ||
      old.highlight != highlight ||
      old.rtl != rtl ||
      old.radius != radius ||
      old.shimmer != shimmer;
}

/// A loading region: one shared shimmer and a single "Loading" announcement
/// for screen readers (the blocks themselves are silent).
class SbSkeletonGroup extends StatelessWidget {
  const SbSkeletonGroup({super.key, required this.child, this.label = 'Loading'});

  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    container: true,
    child: SbShimmer(child: child),
  );
}

/// A scrolling list of placeholder rows, laid out like the real list.
class SbSkeletonList extends StatelessWidget {
  const SbSkeletonList({
    super.key,
    required this.item,
    this.count = 6,
    this.padding,
    this.gap = SbSpace.s3,
    this.label = 'Loading',
  });

  final Widget item;
  final int count;
  final EdgeInsetsGeometry? padding;
  final double gap;
  final String label;

  @override
  Widget build(BuildContext context) => SbSkeletonGroup(
    label: label,
    child: ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.all(SbLayout.edge(context)),
      itemCount: count,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, _) => item,
    ),
  );
}

/// Cross-fades from a placeholder to the loaded content (or an error), so
/// content arrives smoothly instead of popping in. Content stays top-aligned
/// in the same slot.
class SbLoadSwitcher extends StatelessWidget {
  const SbLoadSwitcher({super.key, required this.loading, required this.child});

  /// True while [child] is a placeholder.
  final bool loading;
  final Widget child;

  static const Duration duration = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration: still ? Duration.zero : duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey<bool>(loading), child: child),
    );
  }
}

/// Card frame for placeholders (same padding, radius and border as the real
/// cards). Shares one shimmer across its blocks.
class SbSkeletonCard extends StatelessWidget {
  const SbSkeletonCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final card = Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SbRadius.card),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
    // One sweep per card even outside an [SbSkeletonGroup].
    return SbShimmer.maybeOf(context) == null ? SbShimmer(child: card) : card;
  }
}

/// Matches [SbWorkerCard] and person rows (chat list, reviews): avatar,
/// name, a shorter detail line, and a text line.
class SbListRowSkeleton extends StatelessWidget {
  const SbListRowSkeleton({super.key, this.leadingCircle = true});

  final bool leadingCircle;

  @override
  Widget build(BuildContext context) {
    return SbSkeletonCard(
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

/// Matches a notification row: icon, title, two lines of text, time.
class SbNotificationSkeleton extends StatelessWidget {
  const SbNotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SbSkeletonCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SbSkeleton.circle(size: 40),
          SizedBox(width: SbSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SbSkeleton(width: 150, height: 14),
                SizedBox(height: SbSpace.s2),
                SbSkeleton(height: 12),
                SizedBox(height: SbSpace.s1),
                SbSkeleton(width: 180, height: 12),
                SizedBox(height: SbSpace.s2),
                SbSkeleton(width: 60, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches a profile page: big avatar, name, title, stats, then sections.
class SbProfileSkeleton extends StatelessWidget {
  const SbProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final edge = SbLayout.edge(context);
    return SbSkeletonGroup(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s5, edge, SbSpace.s5),
        children: const [
          // A list stretches its children; this column keeps short bars short.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: SbSkeleton.circle(size: 88)),
              SizedBox(height: SbSpace.s4),
              Center(child: SbSkeleton(width: 170, height: 20)),
              SizedBox(height: SbSpace.s2),
              Center(child: SbSkeleton(width: 120, height: 14)),
              SizedBox(height: SbSpace.s5),
              Row(
                children: [
                  Expanded(child: SbSkeleton(height: 56, radius: SbRadius.card)),
                  SizedBox(width: SbSpace.s3),
                  Expanded(child: SbSkeleton(height: 56, radius: SbRadius.card)),
                  SizedBox(width: SbSpace.s3),
                  Expanded(child: SbSkeleton(height: 56, radius: SbRadius.card)),
                ],
              ),
              SizedBox(height: SbSpace.s5),
              _DetailSection(lines: 3),
              SizedBox(height: SbSpace.s3),
              _DetailSection(lines: 2),
            ],
          ),
        ],
      ),
    );
  }
}

/// Matches a details page (job, proposal, contract): heading, meta chips,
/// a paragraph, then content cards.
class SbDetailSkeleton extends StatelessWidget {
  const SbDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final edge = SbLayout.edge(context);
    return SbSkeletonGroup(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s4, edge, SbSpace.s4),
        children: const [
          // A list stretches its children; this column keeps short bars short.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SbSkeleton(width: 90, height: 12),
              SizedBox(height: SbSpace.s2),
              SbSkeleton(height: 22),
              SizedBox(height: SbSpace.s2),
              SbSkeleton(width: 220, height: 22),
              SizedBox(height: SbSpace.s4),
              Row(
                children: [
                  SbSkeleton(width: 84, height: 28, radius: SbRadius.full),
                  SizedBox(width: SbSpace.s2),
                  SbSkeleton(width: 110, height: 28, radius: SbRadius.full),
                ],
              ),
              SizedBox(height: SbSpace.s5),
              _DetailSection(lines: 4),
              SizedBox(height: SbSpace.s3),
              _DetailSection(lines: 2, avatar: true),
              SizedBox(height: SbSpace.s3),
              _DetailSection(lines: 2),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.lines, this.avatar = false});

  final int lines;
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    return SbSkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avatar) ...[
            const Row(
              children: [
                SbSkeleton.circle(size: 40),
                SizedBox(width: SbSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SbSkeleton(width: 130, height: 14),
                      SizedBox(height: SbSpace.s2),
                      SbSkeleton(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SbSpace.s3),
          ] else ...[
            const SbSkeleton(width: 120, height: 14),
            const SizedBox(height: SbSpace.s3),
          ],
          for (var i = 0; i < lines; i++) ...[
            SbSkeleton(width: i == lines - 1 ? 180 : null, height: 12),
            if (i < lines - 1) const SizedBox(height: SbSpace.s2),
          ],
        ],
      ),
    );
  }
}

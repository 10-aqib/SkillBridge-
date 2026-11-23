import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/shared/design_system/sb_skeleton.dart';

/// Skeleton block. Previously hardcoded dark colours (wrong in light mode);
/// now [SbSkeleton], which follows the theme and stops pulsing when the OS
/// asks for reduced motion.
class ShimmerLoadingCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoadingCard({
    super.key,
    this.height = 100.0,
    this.width,
    this.borderRadius = SbRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    return SbSkeleton(
      width: width ?? double.infinity,
      height: height,
      radius: borderRadius,
    );
  }
}

/// Job-row skeleton (same component as [JobShimmerCard]).
class ShimmerJobCardSkeleton extends StatelessWidget {
  const ShimmerJobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SbListRowSkeleton(leadingCircle: false);
}

/// Worker-row skeleton (same component as [WorkerShimmerCard]).
class ShimmerWorkerCardSkeleton extends StatelessWidget {
  const ShimmerWorkerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SbListRowSkeleton();
}

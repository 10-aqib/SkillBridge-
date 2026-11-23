import 'package:flutter/material.dart';
import 'package:skill_bridge/shared/design_system/sb_skeleton.dart';

/// Worker-row loading skeleton. Same shape as before, now one shared
/// implementation ([SbListRowSkeleton]) that follows light/dark and reduced motion.
class WorkerShimmerCard extends StatelessWidget {
  const WorkerShimmerCard({super.key});

  @override
  Widget build(BuildContext context) => const SbListRowSkeleton();
}

/// Job-row loading skeleton.
class JobShimmerCard extends StatelessWidget {
  const JobShimmerCard({super.key});

  @override
  Widget build(BuildContext context) => const SbListRowSkeleton(leadingCircle: false);
}

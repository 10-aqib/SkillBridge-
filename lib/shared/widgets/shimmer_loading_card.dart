import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';

/// Guild Modernist Shimmer Loading Effect.
/// Replaces basic spinners with a metallic glowing skeleton animation.
class ShimmerLoadingCard extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoadingCard({
    super.key,
    this.height = 100.0,
    this.width,
    this.borderRadius = AppDimensions.radiusLg,
  });

  @override
  State<ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<ShimmerLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2.5), -0.3),
              end: Alignment(0.0 + (_controller.value * 2.5), 0.3),
              colors: [
                AppColors.darkCard,
                AppColors.darkCard.withValues(alpha: 0.4),
                AppColors.darkCard,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
            border: Border.all(
              color: AppColors.darkLine.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built Skeleton loader matching the layout of a Job Listing Card
class ShimmerJobCardSkeleton extends StatelessWidget {
  const ShimmerJobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoadingCard(height: 18.0, width: 160.0),
          SizedBox(height: AppDimensions.sm),
          ShimmerLoadingCard(height: 14.0, width: 220.0),
          SizedBox(height: AppDimensions.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoadingCard(height: 28.0, width: 90.0, borderRadius: 14.0),
              ShimmerLoadingCard(height: 28.0, width: 110.0, borderRadius: 14.0),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pre-built Skeleton loader matching the layout of a Worker Profile Card
class ShimmerWorkerCardSkeleton extends StatelessWidget {
  const ShimmerWorkerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: const Row(
        children: [
          ShimmerLoadingCard(height: 52.0, width: 52.0, borderRadius: 26.0),
          SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoadingCard(height: 16.0, width: 140.0),
                SizedBox(height: 8.0),
                ShimmerLoadingCard(height: 12.0, width: 100.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

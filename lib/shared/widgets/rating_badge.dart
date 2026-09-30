import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double iconSize;
  final TextStyle? textStyle;
  final Color? color;
  final bool showReviewCount;

  const RatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.iconSize = 20,
    this.textStyle,
    this.color,
    this.showReviewCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0 || rating == 0) {
      return Text(
        'New • No ratings yet',
        style: textStyle ??
            AppTextStyles.bodyPrimary.copyWith(
              color: context.mutedColor,
            ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: color ?? AppColors.amber,
          size: iconSize,
        ),
        const SizedBox(width: 4),
        Text(
          showReviewCount 
              ? '${rating.toStringAsFixed(1)} ($reviewCount Reviews)'
              : rating.toStringAsFixed(1),
          style: textStyle ??
              AppTextStyles.bodyPrimary.copyWith(
                color: context.textColor,
              ),
        ),
      ],
    );
  }
}

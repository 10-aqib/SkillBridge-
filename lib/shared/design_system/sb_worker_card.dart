import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/config/theme/sb/sb_typography.dart';
import 'package:skill_bridge/shared/design_system/sb_avatar.dart';
import 'package:skill_bridge/shared/design_system/sb_status_badge.dart';

/// Worker row for discovery lists. Order of information follows the trust
/// decision: who → can I trust them → what it costs → can they come.
///
/// Every optional field is hidden when null. Never pass a default rating,
/// fake review count, or invented distance.
class SbWorkerCard extends StatelessWidget {
  const SbWorkerCard({
    super.key,
    required this.name,
    required this.trade,
    this.imageUrl,
    this.verifiedLabel,
    this.rating,
    this.reviewsLabel,
    this.newProfileLabel,
    this.rateLabel,
    this.distanceLabel,
    this.availabilityLabel,
    this.isAvailable,
    this.onTap,
  });

  final String name;

  /// Primary trade / category, localized.
  final String trade;
  final String? imageUrl;

  /// Set only when the profile is verified server-side.
  final String? verifiedLabel;

  /// Aggregate from reviews. Null when there are no reviews.
  final double? rating;

  /// e.g. "32 reviews". Shown next to [rating].
  final String? reviewsLabel;

  /// Shown instead of a rating when the worker has no reviews yet.
  final String? newProfileLabel;

  /// e.g. "Rs 1,500 / visit" or "Rate on request". Caller formats with the
  /// rate basis; never a bare number.
  final String? rateLabel;

  /// Approximate public distance, e.g. "≈ 2 km". Never an exact address.
  final String? distanceLabel;
  final String? availabilityLabel;
  final bool? isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final t = Theme.of(context).textTheme;

    final meta = <Widget>[
      if (rating != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_rounded, size: 16, color: c.accent),
          const SizedBox(width: 2),
          Text(rating!.toStringAsFixed(1), style: SbTypography.numeric(t.labelLarge!)),
          if (reviewsLabel != null) ...[
            const SizedBox(width: SbSpace.s1),
            Text('($reviewsLabel)', style: t.bodySmall),
          ],
        ])
      else if (newProfileLabel != null)
        Text(newProfileLabel!, style: t.bodySmall),
      if (distanceLabel != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.near_me_outlined, size: 14, color: c.textSecondary),
          const SizedBox(width: 2),
          Text(distanceLabel!, style: t.bodySmall),
        ]),
    ];

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.card),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(SbSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SbAvatar(name: name, imageUrl: imageUrl),
              const SizedBox(width: SbSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(name, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (verifiedLabel != null) ...[
                        const SizedBox(width: SbSpace.s1),
                        Tooltip(
                          message: verifiedLabel!,
                          child: Icon(Icons.verified_rounded, size: 18, color: c.success,
                              semanticLabel: verifiedLabel),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(trade, style: t.bodyMedium!.copyWith(color: c.textSecondary)),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: SbSpace.s2),
                      Wrap(spacing: SbSpace.s3, runSpacing: SbSpace.s1, children: meta),
                    ],
                    if (rateLabel != null || availabilityLabel != null) ...[
                      const SizedBox(height: SbSpace.s3),
                      Row(children: [
                        if (rateLabel != null)
                          Expanded(
                            child: Text(rateLabel!,
                                style: SbTypography.numeric(t.labelLarge!.copyWith(color: c.text))),
                          )
                        else
                          const Spacer(),
                        if (availabilityLabel != null)
                          isAvailable == true
                              ? SbStatusBadge.available(label: availabilityLabel!, dense: true)
                              : SbStatusBadge.unavailable(label: availabilityLabel!, dense: true),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

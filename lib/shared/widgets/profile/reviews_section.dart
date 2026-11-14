import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_sections.dart';

/// Reviews this person has received (real reviews only; empty and error
/// states are distinct).
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key, required this.userId, this.maxItems = 5});

  final String userId;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final reviews = ref.watch(userReviewsStreamProvider(userId));

    return ProfileSection(
      title: l.reviews,
      child: reviews.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: SbSpace.s3),
          child: SbListRowSkeleton(),
        ),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          compact: true,
          title: l.profileReviewsError,
          message: l.errNetwork,
        ),
        data: (list) {
          if (list.isEmpty) {
            return SbStateView(
              kind: SbStateKind.empty,
              compact: true,
              icon: Icons.reviews_outlined,
              title: l.profileNoReviews,
              message: l.profileNoReviewsBody,
            );
          }
          final shown = list.take(maxItems).toList();
          return Column(children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) Divider(height: SbSpace.s5, color: c.border),
              MergeSemantics(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(shown[i].reviewerName, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Icon(Icons.star_rounded, size: 16, color: c.accent),
                    const SizedBox(width: 2),
                    Text(shown[i].rating.toStringAsFixed(1), style: SbTypography.numeric(t.labelLarge!)),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(shown[i].createdAt),
                    style: t.bodySmall,
                  ),
                  if (shown[i].comment.trim().isNotEmpty) ...[
                    const SizedBox(height: SbSpace.s2),
                    Text(shown[i].comment, style: t.bodyMedium),
                  ],
                ]),
              ),
            ],
          ]);
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/config/theme/sb/sb_typography.dart';

/// Job row for client "My jobs" and worker discovery. Shows service, area,
/// budget basis, urgency, and proposal count — the things that decide whether
/// to open it.
class SbJobCard extends StatelessWidget {
  const SbJobCard({
    super.key,
    required this.title,
    required this.category,
    this.categoryIcon = Icons.handyman_outlined,
    this.locationLabel,
    this.budgetLabel,
    this.postedLabel,
    this.proposalsLabel,
    this.urgentLabel,
    this.status,
    this.footer,
    this.onTap,
    this.summary,
    this.tags = const [],
    this.byline,
  });

  final String title;
  final String category;
  final IconData categoryIcon;

  /// Area or approximate distance — never the exact address before hire.
  final String? locationLabel;

  /// Budget with basis, e.g. "Rs 3,000 – 5,000 · fixed".
  final String? budgetLabel;
  final String? postedLabel;

  /// e.g. "4 proposals". Hidden when null.
  final String? proposalsLabel;

  /// Set only when the job is flagged urgent.
  final String? urgentLabel;

  /// Status badge (client view) — typically an [SbStatusBadge].
  final Widget? status;

  /// Role-specific actions (Apply / View proposals). Keep to one primary.
  final Widget? footer;
  final VoidCallback? onTap;

  /// Short description (two lines) for discovery feeds.
  final String? summary;

  /// Skills or other short labels; the first three are shown, then "+n".
  final List<String> tags;

  /// Who posted it, e.g. client name and city (public details only).
  final String? byline;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    final tone = SbCategoryTone.forCategory(category).resolve(Theme.of(context).brightness);

    Widget meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: c.textSecondary),
          const SizedBox(width: SbSpace.s1),
          Flexible(child: Text(text, style: t.bodyMedium!.copyWith(color: c.textSecondary))),
        ]);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.background,
                    borderRadius: BorderRadius.circular(SbRadius.control),
                  ),
                  child: Icon(categoryIcon, size: 22, color: tone.foreground),
                ),
                const SizedBox(width: SbSpace.s3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(category, style: t.labelMedium!.copyWith(color: c.textSecondary)),
                    const SizedBox(height: 2),
                    Text(title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                if (status != null) ...[const SizedBox(width: SbSpace.s2), status!],
              ]),
              if (summary != null && summary!.trim().isNotEmpty) ...[
                const SizedBox(height: SbSpace.s2),
                Text(summary!.trim(), style: t.bodyMedium!.copyWith(color: c.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: SbSpace.s3),
                Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                  for (final tag in tags.take(3)) _Tag(tag),
                  if (tags.length > 3) _Tag('+${tags.length - 3}'),
                ]),
              ],
              const SizedBox(height: SbSpace.s3),
              Wrap(spacing: SbSpace.s4, runSpacing: SbSpace.s1, children: [
                if (locationLabel != null) meta(Icons.place_outlined, locationLabel!),
                if (postedLabel != null) meta(Icons.schedule_rounded, postedLabel!),
                if (byline != null) meta(Icons.person_outline_rounded, byline!),
              ]),
              if (budgetLabel != null || urgentLabel != null || proposalsLabel != null) ...[
                const SizedBox(height: SbSpace.s3),
                Divider(color: c.border, height: 1),
                const SizedBox(height: SbSpace.s3),
                Row(children: [
                  if (budgetLabel != null)
                    Expanded(
                      child: Text(budgetLabel!, style: SbTypography.numeric(t.labelLarge!)),
                    )
                  else
                    const Spacer(),
                  if (urgentLabel != null) ...[
                    Icon(Icons.bolt_rounded, size: 16, color: c.onAccentSubtle),
                    Text(urgentLabel!, style: t.labelMedium!.copyWith(color: c.onAccentSubtle)),
                    const SizedBox(width: SbSpace.s3),
                  ],
                  if (proposalsLabel != null)
                    Text(proposalsLabel!, style: t.bodySmall),
                ]),
              ],
              if (footer != null) ...[const SizedBox(height: SbSpace.s3), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SbSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(SbRadius.xs),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: c.textSecondary)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';

/// Status / trust badge. Always icon + text, so meaning never relies on colour.
///
/// Labels come from the caller's localizations, e.g.
/// `SbStatusBadge.verified(label: context.l10n.verified)`.
class SbStatusBadge extends StatelessWidget {
  const SbStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.tone = SbTone.neutral,
    this.dense = false,
  });

  /// Identity or skills checked by SkillBridge. Only show when the backend
  /// says so (e.g. `workerProfile.isVerified == true`) — never inferred.
  const SbStatusBadge.verified({super.key, required this.label, this.dense = false})
      : icon = Icons.verified_rounded,
        tone = SbTone.success;

  const SbStatusBadge.pending({super.key, required this.label, this.dense = false})
      : icon = Icons.schedule_rounded,
        tone = SbTone.warning;

  const SbStatusBadge.available({super.key, required this.label, this.dense = false})
      : icon = Icons.circle,
        tone = SbTone.success;

  const SbStatusBadge.unavailable({super.key, required this.label, this.dense = false})
      : icon = Icons.do_not_disturb_on_outlined,
        tone = SbTone.neutral;

  const SbStatusBadge.urgent({super.key, required this.label, this.dense = false})
      : icon = Icons.bolt_rounded,
        tone = SbTone.accent;

  const SbStatusBadge.info({super.key, required this.label, this.dense = false})
      : icon = Icons.info_outline_rounded,
        tone = SbTone.info;

  const SbStatusBadge.error({super.key, required this.label, this.dense = false})
      : icon = Icons.error_outline_rounded,
        tone = SbTone.error;

  final String label;
  final IconData icon;
  final SbTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final pair = context.sb.tone(tone);
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(color: pair.foreground);
    final small = icon == Icons.circle;
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        dense ? 6 : SbSpace.s2,
        dense ? 2 : SbSpace.s1,
        dense ? SbSpace.s2 : 10,
        dense ? 2 : SbSpace.s1,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(SbRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 8 : (dense ? 12 : 14), color: pair.foreground),
          SizedBox(width: small ? 6 : SbSpace.s1),
          Flexible(
            child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

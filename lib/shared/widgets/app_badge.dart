import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/shared/design_system/sb_status_badge.dart';

/// Legacy status pill API. The named factories render [SbStatusBadge] with the
/// matching semantic tone (correct in light and dark). The plain constructor
/// keeps caller-supplied colours on the same pill geometry.
class AppBadge extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;
  final SbTone? _tone;

  const AppBadge({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  }) : _tone = null;

  const AppBadge._toned(this.text, this.icon, this._tone)
      : textColor = const Color(0x00000000),
        backgroundColor = const Color(0x00000000);

  factory AppBadge.verified(BuildContext context) => AppBadge._toned(
        AppL10n.select(context, en: 'Verified', ur: 'تصدیق شدہ'),
        Icons.verified_rounded,
        SbTone.success,
      );

  factory AppBadge.urgent(BuildContext context) => AppBadge._toned(
        AppL10n.select(context, en: 'URGENT', ur: 'فوری'),
        Icons.bolt_rounded,
        SbTone.accent,
      );

  factory AppBadge.available(BuildContext context) => AppBadge._toned(
        AppL10n.select(context, en: 'Available', ur: 'دستیاب'),
        Icons.circle,
        SbTone.success,
      );

  factory AppBadge.busy(BuildContext context) => AppBadge._toned(
        AppL10n.select(context, en: 'Busy', ur: 'مصروف'),
        Icons.do_not_disturb_on_outlined,
        SbTone.warning,
      );

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    if (tone != null) {
      return SbStatusBadge(label: text, icon: icon ?? Icons.circle, tone: tone);
    }
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(SbSpace.s2, SbSpace.s1, 10, SbSpace.s1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SbRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: SbSpace.s1),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

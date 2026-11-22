import 'package:flutter/material.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Shown instead of a map when it can't be drawn (no map configured in this
/// build, no API key, or the map failed to load).
class SbMapUnavailable extends StatelessWidget {
  const SbMapUnavailable({super.key, required this.title, this.message, this.action});
  final String title;
  final String? message;
  final Widget? action;

  /// The standard "map unavailable" panel with the app's wording.
  factory SbMapUnavailable.standard(BuildContext context, {Widget? action}) {
    final l = context.l10n;
    return SbMapUnavailable(title: l.mapUnavailableTitle, message: l.liveMapUnavailable, action: action);
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: title,
      child: Container(
        color: sb.surfaceSunken,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(SbSpace.s4),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.map_outlined, size: 32, color: sb.textSecondary),
            const SizedBox(height: SbSpace.s2),
            Text(title, style: t.titleSmall, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: SbSpace.s1),
              Text(message!, style: t.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: SbSpace.s3), action!],
          ]),
        ),
      ),
    );
  }
}

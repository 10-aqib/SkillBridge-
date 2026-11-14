import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Road route lines for an `SbMap` (Navigation phase 5): the chosen route on
/// top in the primary colour with a light casing, alternatives underneath in
/// a muted colour.
class SbRouteLayer extends StatelessWidget {
  const SbRouteLayer({super.key, required this.route, this.alternatives = const []});

  final NavRoute route;
  final List<NavRoute> alternatives;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PolylineLayer(polylines: [
      for (final alt in alternatives)
        Polyline(
          points: alt.points,
          strokeWidth: 5,
          color: sb.textSecondary.withValues(alpha: 0.55),
          borderStrokeWidth: 1.5,
          borderColor: sb.surface.withValues(alpha: 0.8),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      Polyline(
        points: route.points,
        strokeWidth: 6,
        color: sb.primary,
        borderStrokeWidth: 2.5,
        borderColor: dark ? const Color(0xCC0B1220) : Colors.white,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    ]);
  }
}

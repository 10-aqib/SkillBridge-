import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Map markers shared by every map (Navigation phase 3).

/// The device's position: a dot with a soft pulse, and an arrow showing the
/// direction of travel when [heading] (degrees from north) is known.
/// With [arrow] (while navigating) the position is an arrow on a white
/// disc instead of a dot: it stays visible on top of the route line, which a
/// dot's heading cone (same colour, pointing along the route) does not.
Marker sbCurrentLocationMarker(LatLng point, {double? heading, String? semanticLabel, bool dimmed = false, bool arrow = false, Key? key}) => Marker(
      key: key,
      point: point,
      width: 56,
      height: 56,
      // Not counter-rotated: the marker turns with the map, so an arrow
      // drawn north-up and turned by the heading points the real way.
      rotate: false,
      // Dimmed while the GPS signal is lost (last known position).
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: arrow
            ? SbNavigationArrow(heading: heading ?? 0, semanticLabel: semanticLabel)
            : SbCurrentLocationDot(heading: heading, semanticLabel: semanticLabel),
      ),
    );

/// A pin whose tip sits on [point] (destination, chosen place).
Marker sbDestinationMarker(LatLng point, {String? semanticLabel, Key? key}) => Marker(
      key: key,
      point: point,
      width: 44,
      height: 52,
      alignment: Alignment.topCenter,
      rotate: true,
      child: SbDestinationPin(semanticLabel: semanticLabel),
    );

/// A person (worker, client) shown by initial; dimmed when their position
/// is out of date.
Marker sbPersonMarker(
  LatLng point, {
  required String name,
  bool selected = false,
  bool stale = false,
  double? heading,
  VoidCallback? onTap,
  Key? key,
}) =>
    Marker(
      key: key,
      point: point,
      width: 84,
      height: 84,
      // With a direction the marker turns with the map so the arrow points
      // the real way; without one it stays upright.
      rotate: heading == null,
      child: heading == null
          ? SbPersonPin(name: name, selected: selected, stale: stale, onTap: onTap)
          : Stack(alignment: Alignment.center, children: [
              Transform.rotate(angle: heading * math.pi / 180, child: const _DirectionCone()),
              SbPersonPin(name: name, selected: selected, stale: stale, onTap: onTap),
            ]),
    );

/// A small arrow above a person pin, pointing up before rotation. Amber
/// with a white outline: it points along the route, so in the route's blue
/// it would disappear into the line.
class _DirectionCone extends StatelessWidget {
  const _DirectionCone();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 84,
        height: 84,
        child: Align(
          alignment: Alignment.topCenter,
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.navigation_rounded, size: 26, color: Colors.white),
            Icon(Icons.navigation_rounded, size: 19, color: context.sb.accent),
          ]),
        ),
      );
}

/// Accuracy circle around a position, in metres.
CircleMarker sbAccuracyCircle(BuildContext context, LatLng point, double meters) {
  final sb = context.sb;
  return CircleMarker(
    point: point,
    radius: meters,
    useRadiusInMeter: true,
    color: sb.primary.withValues(alpha: 0.10),
    borderColor: sb.primary.withValues(alpha: 0.35),
    borderStrokeWidth: 1,
  );
}

class SbCurrentLocationDot extends StatefulWidget {
  const SbCurrentLocationDot({super.key, this.heading, this.semanticLabel});
  final double? heading;
  final String? semanticLabel;

  @override
  State<SbCurrentLocationDot> createState() => _SbCurrentLocationDotState();
}

class _SbCurrentLocationDotState extends State<SbCurrentLocationDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No pulse when the OS asks for reduced motion.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final heading = widget.heading;
    return Semantics(
      label: widget.semanticLabel,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final v = _pulse.value;
            return Container(
              width: 20 + 34 * v,
              height: 20 + 34 * v,
              decoration: BoxDecoration(shape: BoxShape.circle, color: sb.primary.withValues(alpha: 0.28 * (1 - v))),
            );
          },
        ),
        if (heading != null)
          Transform.rotate(
            angle: heading * math.pi / 180,
            child: CustomPaint(size: const Size(40, 40), painter: _HeadingPainter(sb.primary)),
          ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sb.primary,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: SbElevation.overlay,
          ),
        ),
      ]),
    );
  }
}

/// The navigation puck: a white disc with an arrow turned to [heading].
class SbNavigationArrow extends StatelessWidget {
  const SbNavigationArrow({super.key, required this.heading, this.semanticLabel});
  final double heading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Semantics(
      label: semanticLabel,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: sb.primary, width: 2),
            boxShadow: SbElevation.overlay,
          ),
          child: Transform.rotate(
            angle: heading * math.pi / 180,
            child: Icon(Icons.navigation_rounded, color: sb.primary, size: 26),
          ),
        ),
      ),
    );
  }
}

/// A small cone in front of the dot, pointing up (north) before rotation.
class _HeadingPainter extends CustomPainter {
  _HeadingPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final path = Path()
      ..moveTo(c.dx, 0)
      ..lineTo(c.dx + 8, c.dy - 6)
      ..lineTo(c.dx - 8, c.dy - 6)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HeadingPainter old) => old.color != color;
}

class SbDestinationPin extends StatelessWidget {
  const SbDestinationPin({super.key, this.semanticLabel});
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Semantics(
      label: semanticLabel,
      child: Stack(alignment: Alignment.topCenter, children: [
        Icon(Icons.location_on_rounded, size: 52, color: sb.accent, shadows: const [Shadow(blurRadius: 4, color: Color(0x55000000))]),
        Positioned(
          top: 12,
          child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: sb.onAccent)),
        ),
      ]),
    );
  }
}

class SbPersonPin extends StatelessWidget {
  const SbPersonPin({super.key, required this.name, this.selected = false, this.stale = false, this.onTap});
  final String name;
  final bool selected;
  final bool stale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final bg = stale ? sb.textSecondary : (selected ? sb.accent : sb.primary);
    final fg = stale ? sb.surface : (selected ? sb.onAccent : sb.onPrimary);
    final pin = AnimatedContainer(
      duration: SbMotion.of(context, SbMotion.base),
      width: selected ? 44 : 36,
      height: selected ? 44 : 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: SbElevation.overlay,
      ),
      child: Text(initial, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: selected ? 18 : 15)),
    );
    return Semantics(
      label: name,
      button: onTap != null,
      selected: selected,
      child: Center(
        child: onTap == null ? pin : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: pin),
      ),
    );
  }
}

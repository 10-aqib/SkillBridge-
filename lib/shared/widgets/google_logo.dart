import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pixel-perfect vector rendering of the official 4-color Google "G" logo.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;
    final double strokeWidth = w * 0.21;
    final Rect bounds = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: r - strokeWidth / 2,
    );

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Angles in radians:
    // 0 rad = 3 o'clock
    // Blue arc (bottom right corner up to crossbar)
    canvas.drawArc(bounds, 0, math.pi * 0.28, false, bluePaint);

    // Green arc (bottom)
    canvas.drawArc(bounds, math.pi * 0.28, math.pi * 0.54, false, greenPaint);

    // Yellow arc (left side)
    canvas.drawArc(bounds, math.pi * 0.82, math.pi * 0.46, false, yellowPaint);

    // Red arc (top)
    canvas.drawArc(bounds, math.pi * 1.28, math.pi * 0.52, false, redPaint);

    // Blue horizontal crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      cx - strokeWidth * 0.2,
      cy - strokeWidth / 2,
      r + strokeWidth * 0.2,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


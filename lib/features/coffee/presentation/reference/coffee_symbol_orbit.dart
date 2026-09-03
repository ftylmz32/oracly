/// Decorative cup orbit — art direction only, never a detected-symbol claim.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class CoffeeSymbolOrbitPainter extends CustomPainter {
  const CoffeeSymbolOrbitPainter({this.phase = 0});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.50, size.height * 0.54);
    final rx = size.width * 0.42;
    final ry = size.height * 0.36;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.28);
    _dashedOval(canvas, c, rx, ry, paint, phase);

    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final origin = Offset(c.dx + rx * math.cos(a), c.dy + ry * math.sin(a));
      _glyph(canvas, paint, origin, size.shortestSide * 0.036, i);
    }
  }

  void _dashedOval(
    Canvas canvas,
    Offset c,
    double rx,
    double ry,
    Paint paint,
    double phase,
  ) {
    const dashes = 72;
    final drift = phase * math.pi * 2 * 0.04;
    for (var i = 0; i < dashes; i += 2) {
      final a0 = drift + i / dashes * math.pi * 2;
      final a1 = drift + (i + 1) / dashes * math.pi * 2;
      canvas.drawLine(
        Offset(c.dx + rx * math.cos(a0), c.dy + ry * math.sin(a0)),
        Offset(c.dx + rx * math.cos(a1), c.dy + ry * math.sin(a1)),
        paint,
      );
    }
  }

  void _glyph(Canvas canvas, Paint paint, Offset o, double s, int i) {
    final path = Path();
    switch (i) {
      case 0: // kuş — top
        path
          ..moveTo(o.dx - s, o.dy)
          ..quadraticBezierTo(
            o.dx,
            o.dy - s * 1.4,
            o.dx + s * 1.2,
            o.dy - s * 0.1,
          )
          ..moveTo(o.dx - s * 0.1, o.dy)
          ..quadraticBezierTo(
            o.dx + s * 0.2,
            o.dy + s,
            o.dx + s * 0.9,
            o.dy + s * 0.2,
          );
      case 1: // yol — winding road with two trees
        path
          ..moveTo(o.dx - s * 1.05, o.dy + s * 0.95)
          ..quadraticBezierTo(
            o.dx - s * 0.2,
            o.dy + s * 0.45,
            o.dx + s * 0.05,
            o.dy - s * 0.15,
          )
          ..quadraticBezierTo(
            o.dx + s * 0.35,
            o.dy - s * 0.85,
            o.dx + s * 1.05,
            o.dy - s * 1.05,
          )
          ..moveTo(o.dx + s * 0.15, o.dy + s * 0.15)
          ..lineTo(o.dx + s * 0.15, o.dy + s * 0.7)
          ..lineTo(o.dx - s * 0.2, o.dy + s * 0.7)
          ..lineTo(o.dx + s * 0.15, o.dy + s * 0.15)
          ..moveTo(o.dx + s * 0.55, o.dy - s * 0.15)
          ..lineTo(o.dx + s * 0.55, o.dy + s * 0.35)
          ..lineTo(o.dx + s * 0.28, o.dy + s * 0.35)
          ..lineTo(o.dx + s * 0.55, o.dy - s * 0.15);
      case 2: // dağ — bottom right
        path
          ..moveTo(o.dx - s * 1.2, o.dy + s * 0.6)
          ..lineTo(o.dx - s * 0.2, o.dy - s)
          ..lineTo(o.dx + s * 0.35, o.dy + s * 0.1)
          ..lineTo(o.dx + s * 0.7, o.dy - s * 0.45)
          ..lineTo(o.dx + s * 1.25, o.dy + s * 0.6);
      case 3: // anahtar — bottom
        path.addOval(
          Rect.fromCircle(center: Offset(o.dx - s * 0.4, o.dy), radius: s * 0.45),
        );
        path
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + s * 1.15, o.dy)
          ..moveTo(o.dx + s * 0.7, o.dy)
          ..lineTo(o.dx + s * 0.7, o.dy + s * 0.45)
          ..moveTo(o.dx + s, o.dy)
          ..lineTo(o.dx + s, o.dy + s * 0.3);
      case 4: // göz — bottom left
        path.addOval(Rect.fromCenter(center: o, width: s * 2.2, height: s * 1.15));
        canvas.drawCircle(o, s * 0.28, paint);
      default: // kalp — top left
        path
          ..moveTo(o.dx, o.dy + s)
          ..cubicTo(
            o.dx - s * 1.4,
            o.dy,
            o.dx - s * 0.6,
            o.dy - s,
            o.dx,
            o.dy - s * 0.25,
          )
          ..cubicTo(o.dx + s * 0.6, o.dy - s, o.dx + s * 1.4, o.dy, o.dx, o.dy + s);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CoffeeSymbolOrbitPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

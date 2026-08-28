/// Visual starfield + symbolic constellation on the brass plate. Never natal.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'astrology_sign_constellations.dart';

class AstrologyCelestialField extends CustomPainter {
  const AstrologyCelestialField({
    required this.seed,
    this.phase = 0,
    required this.signId,
  });

  final int seed;
  final double phase;
  final String signId;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.48);
    final plateR = size.shortestSide * 0.36;
    final twinkle = 0.62 + math.sin(phase * math.pi * 2) * 0.1;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: plateR)));
    _fieldStars(canvas, c, plateR, twinkle);
    _constellation(canvas, c, size.shortestSide * 0.22, twinkle);
    canvas.restore();
  }

  void _fieldStars(Canvas canvas, Offset c, double plateR, double twinkle) {
    final rnd = math.Random(seed.abs() + 17);
    for (var i = 0; i < 28; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final d = plateR * (0.18 + rnd.nextDouble() * 0.78);
      final p = c + Offset(math.cos(a) * d, math.sin(a) * d);
      final bright = rnd.nextDouble();
      final alpha = (0.1 + bright * 0.38) * twinkle;
      canvas.drawCircle(
        p,
        0.45 + bright * 0.7,
        Paint()..color = OraclyChrome.cream.withValues(alpha: alpha * 0.85),
      );
    }
  }

  void _constellation(Canvas canvas, Offset c, double r, double twinkle) {
    final shape = AstrologySignConstellations.of(signId);
    final pts = AstrologySignConstellations.worldPoints(shape, c, r);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.32 + twinkle * 0.12);
    for (final (a, b) in shape.edges) {
      if (a < pts.length && b < pts.length) {
        canvas.drawLine(pts[a], pts[b], line);
      }
    }
    for (final p in pts) {
      canvas.drawCircle(
        p,
        2.8,
        Paint()
          ..color = OraclyChrome.goldLight.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawCircle(
        p,
        1.25,
        Paint()..color = OraclyChrome.cream.withValues(alpha: 0.92 * twinkle),
      );
      canvas.drawCircle(
        p,
        0.5,
        Paint()..color = OraclyChrome.cream.withValues(alpha: 0.62),
      );
    }
  }

  @override
  bool shouldRepaint(covariant AstrologyCelestialField oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.phase != phase ||
      oldDelegate.signId != signId;
}

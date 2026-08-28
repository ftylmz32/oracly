/// OR Living Core — premium celestial instrument (paint only).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class CompanionOrLivingCorePainter extends CustomPainter {
  CompanionOrLivingCorePainter({
    required this.phase,
    required this.glow,
    this.compact = false,
  });

  final double phase;
  final double glow;
  final bool compact;

  static const _base = Color(0xFF030205);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.36;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            OraclyChrome.goldLight.withValues(alpha: 0.08 + glow * 0.06),
            OraclyChrome.violet.withValues(alpha: 0.10 + glow * 0.05),
            _base,
            const Color(0xFF060408),
          ],
          stops: const [0.0, 0.28, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    final tilt = phase * math.pi * 2;
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.55 : 0.65
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.38 + glow * 0.12);
    _ellipse(canvas, c, r * 1.14, r * 0.36, tilt * 0.28, orbit);
    if (!compact) {
      _ellipse(canvas, c, r * 0.88, r * 0.22, -tilt * 0.18 + 0.6, orbit);
    }

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.85 : 1.05
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.72 + glow * 0.18)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.68),
      -math.pi * 0.78 + tilt * 0.03,
      math.pi * 0.54,
      false,
      arc,
    );

    if (!compact) {
      final node = Paint()
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.55);
      for (var i = 0; i < 2; i++) {
        final a = tilt + i * math.pi;
        canvas.drawCircle(
          Offset(c.dx + math.cos(a) * r * 1.08, c.dy + math.sin(a) * r * 0.34),
          1.0,
          node,
        );
      }
    }
  }

  void _ellipse(
    Canvas canvas,
    Offset c,
    double rx,
    double ry,
    double rot,
    Paint p,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      p,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompanionOrLivingCorePainter old) =>
      old.phase != phase || old.glow != glow || old.compact != compact;
}

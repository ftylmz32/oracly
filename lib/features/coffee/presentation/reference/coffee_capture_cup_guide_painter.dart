/// Top-down cup interior framing — Coffee capture guidance only.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'coffee_reference_tokens.dart';

class CoffeeCaptureCupGuidePainter extends CustomPainter {
  const CoffeeCaptureCupGuidePainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final rx = size.width * 0.31;
    final ry = rx * 0.76;
    final c = Offset(cx, cy);

    _atmosphere(canvas, size, c, rx, ry);
    _cupWell(canvas, c, rx, ry);
    _grounds(canvas, c, rx, ry);
    _rim(canvas, c, rx, ry);
    _handle(canvas, c, rx, ry);
    _steam(canvas, c, ry, pulse);
    _motes(canvas, c, rx, ry, pulse);
  }

  void _atmosphere(Canvas canvas, Size size, Offset c, double rx, double ry) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.72, -0.2),
          radius: 1.1,
          colors: [
            OraclyChrome.violet.withValues(alpha: 0.22),
            const Color(0xFF0A0614),
            const Color(0xFF050308),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 2.8, height: ry * 3.2),
      Paint()
        ..color = CoffeeReferenceTokens.amberGlow.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  void _cupWell(Canvas canvas, Offset c, double rx, double ry) {
    final wall = Path()
      ..addOval(Rect.fromCenter(center: c, width: rx * 2.04, height: ry * 2.04))
      ..addOval(Rect.fromCenter(center: c, width: rx * 1.62, height: ry * 1.62))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      wall,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2A1418),
            const Color(0xFF12080C),
            const Color(0xFF08040A),
          ],
        ).createShader(Rect.fromCenter(center: c, width: rx * 2, height: ry * 2)),
    );
  }

  void _grounds(Canvas canvas, Offset c, double rx, double ry) {
    final bowl = Rect.fromCenter(center: c, width: rx * 1.58, height: ry * 1.58);
    canvas.drawOval(
      bowl,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3D2418).withValues(alpha: 0.92),
            CoffeeReferenceTokens.cupWell,
            const Color(0xFF050204),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bowl),
    );
    final speck = Paint()..color = const Color(0xFF5A3828).withValues(alpha: 0.35);
    for (var i = 0; i < 5; i++) {
      final a = i * 1.25 + 0.4;
      final r = rx * (0.18 + i * 0.07);
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r * 0.7),
        2.2 + i * 0.3,
        speck,
      );
    }
  }

  void _rim(Canvas canvas, Offset c, double rx, double ry) {
    final outer = Rect.fromCenter(center: c, width: rx * 2.06, height: ry * 2.06);
    canvas.drawOval(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.62 + pulse * 0.12),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 1.92, height: ry * 1.92),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..color = OraclyChrome.gold.withValues(alpha: 0.28),
    );
    canvas.drawArc(
      Rect.fromCenter(center: c, width: rx * 2.1, height: ry * 2.1),
      -2.4,
      0.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.38 + pulse * 0.1),
    );
  }

  void _handle(Canvas canvas, Offset c, double rx, double ry) {
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx + rx * 1.02, c.dy + ry * 0.04),
        width: rx * 0.72,
        height: ry * 0.88,
      ),
      -0.8,
      2.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = OraclyChrome.goldMuted.withValues(alpha: 0.42),
    );
  }

  void _steam(Canvas canvas, Offset c, double ry, double pulse) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = OraclyChrome.cream.withValues(alpha: 0.14 + pulse * 0.06);
    for (final dx in [-8.0, 0.0, 10.0]) {
      final path = Path()
        ..moveTo(c.dx + dx, c.dy - ry * 0.42)
        ..quadraticBezierTo(
          c.dx + dx * 0.4,
          c.dy - ry * 0.72,
          c.dx + dx * 0.2,
          c.dy - ry * 0.95,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _motes(Canvas canvas, Offset c, double rx, double ry, double pulse) {
    final paint = Paint()
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.22 + pulse * 0.12);
    for (final o in [
      Offset(c.dx - rx * 0.9, c.dy - ry * 0.55),
      Offset(c.dx + rx * 1.05, c.dy - ry * 0.2),
      Offset(c.dx + rx * 0.75, c.dy + ry * 0.85),
    ]) {
      canvas.drawCircle(o, 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CoffeeCaptureCupGuidePainter old) =>
      old.pulse != pulse;
}
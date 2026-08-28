/// Cinematic coffee cup painter — gold rim, grounds, drifting steam.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class CoffeeCupPainter extends CustomPainter {
  const CoffeeCupPainter({this.phase = 0});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.62;
    final cupW = size.width * 0.62;
    final cupH = size.height * 0.52;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: cupW * 1.7, height: cupH * 1.5),
      Paint()
        ..color = OraclyChrome.gold.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      Offset(cx, cy - cupH * 0.2),
      cupW * 0.85,
      Paint()
        ..color = OraclyChrome.violet.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    final saucer = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, cy + cupH * 0.48),
          width: cupW * 1.55,
          height: cupH * 0.22,
        ),
      );
    canvas.drawPath(
      saucer,
      Paint()
        ..shader = LinearGradient(
          colors: [
            OraclyChrome.goldLight.withValues(alpha: 0.55),
            OraclyChrome.goldMuted.withValues(alpha: 0.28),
          ],
        ).createShader(saucer.getBounds()),
    );

    final body = Path()
      ..moveTo(cx - cupW * 0.46, cy - cupH * 0.32)
      ..lineTo(cx - cupW * 0.34, cy + cupH * 0.38)
      ..quadraticBezierTo(cx, cy + cupH * 0.48, cx + cupW * 0.34, cy + cupH * 0.38)
      ..lineTo(cx + cupW * 0.46, cy - cupH * 0.32)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A1A18),
            const Color(0xFF12080C),
            OraclyChrome.violet.withValues(alpha: 0.55),
          ],
        ).createShader(body.getBounds()),
    );

    final rim = Rect.fromCenter(
      center: Offset(cx, cy - cupH * 0.32),
      width: cupW * 0.94,
      height: cupH * 0.22,
    );
    canvas.drawOval(rim, Paint()..color = const Color(0xFF1A0C10));
    canvas.drawOval(
      rim.deflate(size.width * 0.018),
      Paint()..color = const Color(0xFF4A2818),
    );
    canvas.drawOval(
      rim.deflate(size.width * 0.038),
      Paint()..color = const Color(0xFF2A140C),
    );
    canvas.drawOval(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.88),
    );

    final handle = Path()
      ..moveTo(cx + cupW * 0.44, cy - cupH * 0.12)
      ..quadraticBezierTo(cx + cupW * 0.82, cy, cx + cupW * 0.42, cy + cupH * 0.22);
    canvas.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = OraclyChrome.gold.withValues(alpha: 0.72),
    );

    final drift = math.sin(phase * math.pi * 2);
    _steam(canvas, Offset(cx - cupW * 0.08, cy - cupH * 0.52 + drift * 2), size.width * 0.08);
    _steam(canvas, Offset(cx + cupW * 0.06, cy - cupH * 0.58 - drift * 2), size.width * 0.07);
  }

  void _steam(Canvas canvas, Offset origin, double amp) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..cubicTo(
        origin.dx + amp,
        origin.dy - amp * 1.4,
        origin.dx - amp,
        origin.dy - amp * 2.4,
        origin.dx + amp * 0.2,
        origin.dy - amp * 3.2,
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant CoffeeCupPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

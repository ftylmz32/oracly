/// Dark table, candle bloom, violet haze — coffee art direction only.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class CoffeeAtmospherePainter extends CustomPainter {
  const CoffeeAtmospherePainter({this.phase = 0});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.48;
    final cy = size.height * 0.62;
    final flicker = 0.88 + math.sin(phase * math.pi * 2) * 0.12;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + size.height * 0.18),
        width: size.width * 0.92,
        height: size.height * 0.28,
      ),
      Paint()
        ..color = const Color(0xFF080406).withValues(alpha: 0.72)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      Offset(cx - size.width * 0.28, cy + size.height * 0.08),
      size.width * 0.22,
      Paint()
        ..color = const Color(0xFFC47A2A).withValues(alpha: 0.22 * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
      Offset(cx + size.width * 0.18, cy - size.height * 0.22),
      size.width * 0.34,
      Paint()
        ..color = OraclyChrome.violet.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  @override
  bool shouldRepaint(covariant CoffeeAtmospherePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Dark walnut table, candle bloom, quiet gold ritual objects.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class CoffeeTablePainter extends CustomPainter {
  const CoffeeTablePainter({this.phase = 0});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.52;
    final cy = size.height * 0.62;
    final flicker = 0.82 + math.sin(phase * math.pi * 2) * 0.18;
    _wood(canvas, size, cx, cy);
    _candle(canvas, Offset(size.width * 0.18, cy - size.height * 0.08), flicker);
    _cezve(canvas, Offset(size.width * 0.86, cy - size.height * 0.02));
    _spoon(canvas, Offset(cx + size.width * 0.18, cy + size.height * 0.16));
  }

  void _wood(Canvas canvas, Size size, double cx, double cy) {
    final table = Rect.fromCenter(
      center: Offset(cx, cy + size.height * 0.18),
      width: size.width * 1.18,
      height: size.height * 0.52,
    );
    canvas.drawOval(
      table,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3A2418),
            const Color(0xFF140A08),
            const Color(0xFF070406),
          ],
        ).createShader(table),
    );
    canvas.drawOval(
      table.deflate(size.width * 0.04),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = OraclyChrome.gold.withValues(alpha: 0.14),
    );
  }

  void _candle(Canvas canvas, Offset p, double flicker) {
    final body = Rect.fromCenter(center: p, width: 14, height: 46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..color = const Color(0xFFE8D8B8).withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      Offset(p.dx, p.dy - 32),
      18 * flicker,
      Paint()
        ..color = const Color(0xFFFFB14A).withValues(alpha: 0.22 * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    final flame = Path()
      ..moveTo(p.dx, p.dy - 44 * flicker)
      ..quadraticBezierTo(p.dx + 6, p.dy - 28, p.dx, p.dy - 22)
      ..quadraticBezierTo(p.dx - 6, p.dy - 28, p.dx, p.dy - 44 * flicker);
    canvas.drawPath(flame, Paint()..color = const Color(0xFFFFC56A));
  }

  void _cezve(Canvas canvas, Offset p) {
    final body = Path()
      ..moveTo(p.dx - 18, p.dy + 10)
      ..lineTo(p.dx - 12, p.dy - 16)
      ..lineTo(p.dx + 12, p.dy - 16)
      ..lineTo(p.dx + 18, p.dy + 10)
      ..close();
    canvas.drawPath(
      body,
      Paint()..color = OraclyChrome.gold.withValues(alpha: 0.34),
    );
    canvas.drawLine(
      Offset(p.dx + 12, p.dy - 10),
      Offset(p.dx + 28, p.dy - 22),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = OraclyChrome.gold.withValues(alpha: 0.48),
    );
  }

  void _spoon(Canvas canvas, Offset p) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.42);
    canvas.drawOval(Rect.fromCenter(center: p, width: 18, height: 10), paint);
    canvas.drawLine(p + const Offset(8, 0), p + const Offset(34, 8), paint);
  }

  @override
  bool shouldRepaint(covariant CoffeeTablePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

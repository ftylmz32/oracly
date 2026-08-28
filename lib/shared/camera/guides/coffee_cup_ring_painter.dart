/// Cup ring + vignette — framing geometry only.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';

class CoffeeCupRingPainter extends CustomPainter {
  const CoffeeCupRingPainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;
    final r = (size.shortestSide * 0.34).clamp(72.0, 148.0);
    final center = Offset(cx, cy);

    final vignette = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: r * 1.08))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      vignette,
      Paint()..color = const Color(0xFF07040F).withValues(alpha: 0.42),
    );

    canvas.drawCircle(
      center,
      r + 14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..color = OraclyChrome.gold.withValues(alpha: 0.045 + pulse * 0.03),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = OraclyChrome.gold.withValues(alpha: 0.52 + pulse * 0.12),
    );
    canvas.drawCircle(
      center,
      r * 0.58,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.26),
    );
    canvas.drawCircle(
      center,
      r * 0.42,
      Paint()
        ..color = const Color(0xFFC47A2A).withValues(alpha: 0.04 + pulse * 0.02),
    );
    _brackets(canvas, center, r);
  }

  void _brackets(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.55);
    const len = 14.0;
    final points = <Offset>[
      Offset(c.dx - r * 0.72, c.dy - r * 0.72),
      Offset(c.dx + r * 0.72, c.dy - r * 0.72),
      Offset(c.dx - r * 0.72, c.dy + r * 0.72),
      Offset(c.dx + r * 0.72, c.dy + r * 0.72),
    ];
    for (final p in points) {
      final sx = p.dx < c.dx ? 1.0 : -1.0;
      final sy = p.dy < c.dy ? 1.0 : -1.0;
      canvas.drawLine(p, Offset(p.dx + sx * len, p.dy), paint);
      canvas.drawLine(p, Offset(p.dx, p.dy + sy * len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CoffeeCupRingPainter old) => old.pulse != pulse;
}

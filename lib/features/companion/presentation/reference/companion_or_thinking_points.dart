/// Three quiet orbit points while OR thinks — not a spinner.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompanionOrThinkingPoints extends StatelessWidget {
  const CompanionOrThinkingPoints({
    super.key,
    required this.size,
    required this.phase,
    required this.color,
  });

  final double size;
  final double phase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ThinkingPointsPainter(phase: phase, color: color),
    );
  }
}

class _ThinkingPointsPainter extends CustomPainter {
  _ThinkingPointsPainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.46;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 3; i++) {
      final a = phase * math.pi * 2 + i * (math.pi * 2 / 3);
      final pulse = 0.35 + 0.65 * ((math.sin(a * 2) + 1) * 0.5);
      paint.color = color.withValues(alpha: 0.28 + pulse * 0.5);
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        1.6 + pulse * 0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingPointsPainter old) =>
      old.phase != phase || old.color != color;
}

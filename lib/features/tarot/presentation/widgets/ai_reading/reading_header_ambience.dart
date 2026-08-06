/// OR-301+ — Faint magical dust, energy field & aura around the living card.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import 'reading_element_theme.dart';

class ReadingHeaderAmbience extends StatelessWidget {
  const ReadingHeaderAmbience({
    super.key,
    required this.theme,
    required this.phase,
  });

  final ReadingElementTheme theme;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _HeaderAmbiencePainter(
          glowColor: theme.glowColor,
          phase: phase,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HeaderAmbiencePainter extends CustomPainter {
  _HeaderAmbiencePainter({required this.glowColor, required this.phase});

  final Color glowColor;
  final double phase;

  static const _dust = <(double x, double y)>[
    (0.18, 0.22),
    (0.82, 0.18),
    (0.72, 0.78),
    (0.28, 0.72),
    (0.5, 0.12),
    (0.12, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final radius = size.width * 0.52;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = glowColor.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(phase * pi * 2 * 0.04);
    canvas.drawCircle(
      Offset.zero,
      radius * 0.88,
      Paint()
        ..color = glowColor.withValues(alpha: 0.045)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.restore();

    for (var i = 0; i < _dust.length; i++) {
      final (x, y) = _dust[i];
      final drift = sin(phase * pi * 2 + i * 1.3) * 2.5;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y + cos(phase + i) * 1.5),
        0.7 + i * 0.08,
        Paint()
          ..color = glowColor.withValues(
            alpha: 0.04 + sin(phase * pi * 2 + i) * 0.025,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderAmbiencePainter old) =>
      old.phase != phase || old.glowColor != glowColor;
}

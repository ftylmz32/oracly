/// OR-1000 — Tarot particle field painter.
library;

import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TarotParticlePainter extends CustomPainter {
  const TarotParticlePainter({required this.phase});

  final double phase;

  static const _seeds = <(double u, double v, double size, double alpha)>[
    (0.12, 0.18, 1.6, 0.35),
    (0.78, 0.22, 1.2, 0.28),
    (0.44, 0.62, 1.8, 0.32),
    (0.22, 0.74, 1.0, 0.24),
    (0.86, 0.58, 1.4, 0.30),
    (0.58, 0.34, 1.1, 0.26),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (u, v, dot, alpha) in _seeds) {
      final drift = phase + u * 3.1;
      final x = size.width * u + cos(drift) * 6;
      final y = size.height * v + sin(drift * 1.17) * 8;
      final paint = Paint()
        ..color = AppColors.goldLight.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(x, y), dot, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TarotParticlePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class TarotGlowPainter extends CustomPainter {
  const TarotGlowPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.28);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [accent, accent.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.55));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant TarotGlowPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

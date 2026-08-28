/// Seeded depth layers - far / mid / near - painted once per frame.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class AstrologyStarfieldPainter extends CustomPainter {
  const AstrologyStarfieldPainter({
    required this.phase,
    this.intensity = 1.0,
    this.still = false,
  });

  final double phase;
  final double intensity;
  final bool still;

  static const _stars = <(double, double, double, double, int)>[
    (0.07, 0.08, 0.55, 0.055, 0),
    (0.19, 0.04, 0.50, 0.045, 0),
    (0.31, 0.11, 0.60, 0.050, 0),
    (0.48, 0.06, 0.45, 0.040, 0),
    (0.66, 0.09, 0.55, 0.048, 0),
    (0.82, 0.05, 0.50, 0.042, 0),
    (0.93, 0.14, 0.45, 0.038, 0),
    (0.12, 0.22, 0.50, 0.044, 0),
    (0.41, 0.19, 0.45, 0.036, 0),
    (0.74, 0.24, 0.55, 0.042, 0),
    (0.88, 0.31, 0.45, 0.034, 0),
    (0.05, 0.36, 0.50, 0.040, 0),
    (0.27, 0.42, 0.45, 0.032, 0),
    (0.58, 0.38, 0.50, 0.038, 0),
    (0.95, 0.48, 0.45, 0.030, 0),
    (0.16, 0.55, 0.50, 0.036, 0),
    (0.49, 0.58, 0.45, 0.028, 0),
    (0.71, 0.52, 0.50, 0.034, 0),
    (0.09, 0.72, 0.45, 0.030, 0),
    (0.38, 0.78, 0.50, 0.032, 0),
    (0.62, 0.70, 0.45, 0.028, 0),
    (0.86, 0.76, 0.50, 0.034, 0),
    (0.24, 0.16, 0.85, 0.070, 1),
    (0.56, 0.13, 0.75, 0.060, 1),
    (0.78, 0.20, 0.90, 0.065, 1),
    (0.14, 0.34, 0.80, 0.055, 1),
    (0.45, 0.30, 0.85, 0.062, 1),
    (0.68, 0.42, 0.75, 0.050, 1),
    (0.90, 0.56, 0.80, 0.055, 1),
    (0.32, 0.62, 0.85, 0.058, 1),
    (0.54, 0.74, 0.75, 0.048, 1),
    (0.80, 0.66, 0.80, 0.052, 1),
    (0.18, 0.28, 1.15, 0.085, 2),
    (0.62, 0.18, 1.05, 0.075, 2),
    (0.42, 0.48, 1.20, 0.080, 2),
    (0.76, 0.58, 1.00, 0.070, 2),
    (0.28, 0.70, 1.10, 0.072, 2),
  ];

  static const _ampX = <double>[1.6, 3.4, 5.8];
  static const _ampY = <double>[1.0, 2.2, 3.6];

  @override
  void paint(Canvas canvas, Size size) {
    final t = still ? 0.35 : phase;
    final paint = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final (nx, ny, r, a, depth) = _stars[i];
      final drift = still
          ? Offset.zero
          : Offset(
              math.sin(t * math.pi * 2 + i * 0.41) * _ampX[depth],
              math.cos(t * math.pi * 2 * 0.72 + i * 0.27) * _ampY[depth],
            );
      final tw = still
          ? 0.72
          : 0.62 + math.sin(t * math.pi * 2 + i * 0.63) * 0.22;
      final gold = depth == 2 || i % 5 == 0;
      paint.color = (gold ? OraclyChrome.goldLight : OraclyChrome.cream)
          .withValues(alpha: a * tw * intensity);
      canvas.drawCircle(
        Offset(size.width * nx, size.height * ny) + drift,
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AstrologyStarfieldPainter old) =>
      old.phase != phase ||
      old.intensity != intensity ||
      old.still != still;
}

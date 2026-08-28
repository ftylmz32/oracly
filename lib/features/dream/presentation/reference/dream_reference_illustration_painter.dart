/// Indigo dream atmosphere — purple glow, cool stars, soft clouds.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DreamAtmospherePainter extends CustomPainter {
  const DreamAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.08),
          radius: 1.06,
          colors: [
            AppColors.secondaryPurple.withValues(alpha: 0.46),
            AppColors.purple.withValues(alpha: 0.42),
            AppColors.purpleDark.withValues(alpha: 0.94),
            AppColors.backgroundSecondary.withValues(alpha: 0.98),
          ],
          stops: const [0.0, 0.28, 0.66, 1.0],
        ).createShader(Offset.zero & size),
    );

    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.shortestSide * 0.58;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.secondaryPurple.withValues(alpha: 0.16),
            AppColors.purpleGlow.withValues(alpha: 0.28),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.40, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    _paintClouds(canvas, size);
    _paintStars(canvas, size);
  }

  void _paintClouds(Canvas canvas, Size size) {
    final base = size.height * 0.80;
    final cloud = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.secondaryPurple.withValues(alpha: 0.18),
          AppColors.surfaceElevated.withValues(alpha: 0.28),
          AppColors.purpleDark.withValues(alpha: 0.16),
        ],
      ).createShader(Rect.fromLTWH(0, base - 36, size.width, size.height));

    void puff(double cx, double cy, double r) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2.4, height: r),
        cloud,
      );
    }

    puff(size.width * 0.18, base, 28);
    puff(size.width * 0.38, base + 6, 34);
    puff(size.width * 0.58, base - 2, 32);
    puff(size.width * 0.80, base + 8, 30);
  }

  void _paintStars(Canvas canvas, Size size) {
    const seeds = <(double, double, double)>[
      (0.12, 0.14, 1.5),
      (0.88, 0.16, 1.2),
      (0.08, 0.42, 1.0),
      (0.92, 0.46, 1.3),
      (0.22, 0.72, 0.9),
      (0.78, 0.70, 1.1),
      (0.50, 0.08, 1.4),
    ];
    for (final (ux, uy, r) in seeds) {
      final p = Offset(size.width * ux, size.height * uy);
      canvas.drawCircle(
        p,
        r,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.42),
      );
      canvas.drawCircle(
        p,
        r * 2.2,
        Paint()..color = AppColors.purpleGlow.withValues(alpha: 0.16),
      );
    }

    final dust = Paint()..color = AppColors.secondaryPurple.withValues(alpha: 0.34);
    for (var i = 0; i < 12; i++) {
      final seed = math.sin((i + 1) * 5.3) * 43758.5453;
      final u = seed - seed.floor();
      final v = math.sin((i + 4) * 2.7) * 12345.6789;
      final w = v - v.floor();
      canvas.drawCircle(
        Offset(size.width * (0.10 + u * 0.80), size.height * (0.10 + w * 0.70)),
        0.6 + u,
        dust,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DreamAtmospherePainter oldDelegate) => false;
}

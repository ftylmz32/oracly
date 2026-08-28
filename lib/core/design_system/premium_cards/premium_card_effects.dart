/// EPIC-023 — Subtle card effects: shimmer sweep and dust particles.
library;

import 'dart:math' show Random, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Very slow shimmer — light sweep across the card surface.
class PremiumCardShimmer extends StatelessWidget {
  const PremiumCardShimmer({
    super.key,
    required this.phase,
    this.intensity = 0.12,
    this.borderRadius = BorderRadius.zero,
  });

  final double phase;
  final double intensity;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _ShimmerPainter(phase: phase, intensity: intensity),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.phase, required this.intensity});

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final sweep = (phase * 2 - 1) * size.width;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppColors.goldLight.withValues(alpha: intensity * 0.35),
          Colors.transparent,
        ],
        stops: const [0.42, 0.5, 0.58],
        transform: GradientRotation(0),
      ).createShader(
        Rect.fromLTWH(sweep - size.width * 0.3, 0, size.width * 0.6, size.height),
      );

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

/// Tiny gold particles — nearly invisible drift.
class PremiumCardParticles extends StatelessWidget {
  const PremiumCardParticles({
    super.key,
    required this.phase,
    this.seed = 7,
    this.density = 14,
  });

  final double phase;
  final int seed;
  final int density;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(phase: phase, seed: seed, density: density),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.phase,
    required this.seed,
    required this.density,
  });

  final double phase;
  final int seed;
  final int density;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < density; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final drift = sin(phase * pi * 2 + i * 0.8) * 3;
      paint.color = AppColors.goldLight.withValues(
        alpha: 0.025 + random.nextDouble() * 0.04,
      );
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(x, baseY + drift),
        1.0 + random.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

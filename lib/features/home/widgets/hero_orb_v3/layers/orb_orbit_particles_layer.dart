/// EPIC-013 — Soft magical particles orbiting outside the crystal shell.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_animation.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_performance.dart';
import '../orb_render_context.dart';

class OrbOrbitParticlesPainter extends CustomPainter {
  OrbOrbitParticlesPainter({
    required this.context,
    required this.phase,
    required this.particleCount,
    this.intensity = 1,
  });

  final OrbRenderContext context;
  final double phase;
  final int particleCount;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (particleCount <= 0) return;

    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final orbitRadius = radius * OrbConstants.externalOrbitRadiusScale;

    for (var i = 0; i < particleCount; i++) {
      final seed = i * 0.6180339887;
      final angle = (phase + seed) * pi * 2;
      final wobble =
          sin((phase + seed * 1.7) * pi * 2) * OrbConstants.externalOrbitWobble;
      final r = orbitRadius * (1 + wobble);
      final pos = center + Offset(cos(angle) * r, sin(angle) * r * 0.92);
      final twinkle = 0.45 + sin((phase + seed) * pi * 4) * 0.25;
      final dotRadius = radius * (0.0045 + (i % 3) * 0.0008);

      canvas.drawCircle(
        pos,
        dotRadius,
        OrbPaint.aa(
          blendMode: BlendMode.plus,
          color: AppColors.goldLight.withValues(
            alpha: twinkle * 0.55 * intensity,
          ),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbOrbitParticlesPainter oldDelegate) {
    return (oldDelegate.phase - phase).abs() > 0.001 ||
        oldDelegate.particleCount != particleCount ||
        oldDelegate.intensity != intensity;
  }
}

class OrbOrbitParticlesLayer extends StatelessWidget {
  const OrbOrbitParticlesLayer({
    super.key,
    required this.motion,
    required this.layoutSize,
    required this.canvasSize,
    required this.tier,
    this.intensity = 1.0,
  });

  final OrbAnimationBundle motion;
  final double layoutSize;
  final double canvasSize;
  final OrbPerformanceTier tier;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final count = OrbPerformance.orbitParticleCount(tier);
    if (!OrbPerformance.enableExternalOrbit(tier) || count == 0) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: motion.orbit,
        builder: (context, _) {
          return CustomPaint(
            painter: OrbOrbitParticlesPainter(
              context: OrbRenderContext.static(
                layoutSize: layoutSize,
                canvasSize: canvasSize,
              ),
              phase: motion.orbitPhase,
              particleCount: count,
              intensity: intensity,
            ),
            size: Size.square(canvasSize),
          );
        },
      ),
    );
  }
}

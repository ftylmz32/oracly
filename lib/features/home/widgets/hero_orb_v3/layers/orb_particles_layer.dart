/// OR-500 — Slow floating particles + magical dust.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_animation.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

class OrbParticlesPainter extends CustomPainter {
  OrbParticlesPainter({
    required this.context,
    required this.motion,
    this.intensity = 1.0,
  });

  final OrbRenderContext context;
  final OrbAnimationBundle motion;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final phase = context.particlePhase * pi * 2;
    final dust = OrbConstants.dustVisibility;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    for (final seed in OrbParticleField.seeds) {
      _drawParticle(canvas, center, radius, phase, seed, 0.30);
    }

    for (final seed in OrbParticleField.dustSeeds) {
      _drawParticle(canvas, center, radius, phase, seed, dust);
    }

    canvas.restore();
  }

  void _drawParticle(
    Canvas canvas,
    Offset center,
    double radius,
    double phase,
    OrbParticleSeed seed,
    double visibility,
  ) {
    final drift = phase * seed.driftRate + seed.phase;
    final px = seed.u + cos(drift) * seed.orbit;
    final py = seed.v + sin(drift * 1.13) * seed.orbit;
    final pos = center + Offset(px * radius, py * radius);
    final fade = motion.particleFade(seed).clamp(0.0, 1.0);

    if (fade <= 0.01) return;

    canvas.drawCircle(
      pos,
      radius * seed.size,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        color: AppColors.goldLight.withValues(
          alpha: seed.alpha * fade * visibility * intensity,
        ),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant OrbParticlesPainter oldDelegate) {
    return oldDelegate.context.particlePhase != context.particlePhase ||
        oldDelegate.intensity != intensity;
  }
}

class OrbParticlesLayer extends StatelessWidget {
  const OrbParticlesLayer({
    super.key,
    required this.motion,
    required this.layoutSize,
    required this.canvasSize,
    this.intensity = 1.0,
  });

  final OrbAnimationBundle motion;
  final double layoutSize;
  final double canvasSize;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: motion.particleDrift,
        builder: (context, _) {
          return CustomPaint(
            painter: OrbParticlesPainter(
              context: OrbRenderContext(
                layoutSize: layoutSize,
                canvasSize: canvasSize,
                innerGlowOpacity: 1,
                ringClockwiseAngle: 0,
                ringCounterClockwiseAngle: 0,
                particlePhase: motion.particlePhase,
              ),
              motion: motion,
              intensity: intensity,
            ),
            size: Size.square(canvasSize),
          );
        },
      ),
    );
  }
}

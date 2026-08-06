/// OR-500 — Core golden glow behind the OR logo (animated).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_animation.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

/// Warm radiance placed before the logo so light sits behind, not on top.
class OrbCoreGlowPainter extends CustomPainter {
  OrbCoreGlowPainter({required this.context});

  final OrbRenderContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = OrbConstants.goldenIlluminationStrength;
    final opacity = context.innerGlowOpacity;
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final logoR = context.normScalar(OrbConstants.logoRadiusNorm);

    canvas.save();
    canvas.clipPath(context.sphereClip());

    canvas.drawCircle(
      center + Offset(0, radius * 0.16),
      radius * 0.50,
      OrbPaint.aa(
        blendMode: BlendMode.softLight,
        shader: ui.Gradient.radial(
          center + Offset(0, radius * 0.16),
          radius * 0.50,
          [
            AppColors.transparent,
            const Color(0xFFFF9A4D).withValues(alpha: 0.10 * opacity * gold),
            AppColors.goldLight.withValues(alpha: 0.14 * opacity * gold),
            AppColors.transparent,
          ],
          const [0.0, 0.38, 0.58, 1.0],
        ),
      ),
    );

    canvas.drawCircle(
      center + Offset(0, radius * 0.06),
      logoR * 2.2,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, logoR * 0.55),
        shader: ui.Gradient.radial(
          center + Offset(0, radius * 0.06),
          logoR * 2.2,
          [
            AppColors.goldLight.withValues(alpha: 0.20 * opacity * gold),
            AppColors.gold.withValues(alpha: 0.10 * opacity * gold),
            AppColors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
      ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbCoreGlowPainter oldDelegate) {
    return oldDelegate.context.innerGlowOpacity != context.innerGlowOpacity;
  }
}

class OrbCoreGlowLayer extends StatelessWidget {
  const OrbCoreGlowLayer({
    super.key,
    required this.motion,
    required this.layoutSize,
    required this.canvasSize,
    this.rewardBoost = 1.0,
  });

  final OrbAnimationBundle motion;
  final double layoutSize;
  final double canvasSize;
  final double rewardBoost;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: motion.innerGlow,
        builder: (context, _) {
          return CustomPaint(
            painter: OrbCoreGlowPainter(
              context: OrbRenderContext(
                layoutSize: layoutSize,
                canvasSize: canvasSize,
                innerGlowOpacity: motion.innerGlowOpacity * rewardBoost,
                ringClockwiseAngle: 0,
                ringCounterClockwiseAngle: 0,
                particlePhase: 0,
              ),
            ),
            size: Size.square(canvasSize),
          );
        },
      ),
    );
  }
}

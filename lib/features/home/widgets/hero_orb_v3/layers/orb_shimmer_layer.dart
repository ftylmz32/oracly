/// EPIC-013 — Occasional light sweep across the crystal surface.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_animation.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

class OrbShimmerPainter extends CustomPainter {
  OrbShimmerPainter({
    required this.context,
    required this.sweep,
    this.intensity = 1,
  });

  final OrbRenderContext context;
  final double sweep;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweep < 0) return;

    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final angle = -pi * 0.35 + sweep * pi * 0.95;
    final bandCenter = center +
        Offset(cos(angle) * radius * 0.42, sin(angle) * radius * 0.42);
    final bandRadius = radius * 0.72;
    final alpha = (0.10 + sin(sweep * pi) * 0.14) * intensity;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    canvas.drawCircle(
      bandCenter,
      bandRadius,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.16),
        shader: ui.Gradient.linear(
          bandCenter + Offset(-bandRadius, -bandRadius * 0.2),
          bandCenter + Offset(bandRadius, bandRadius * 0.2),
          [
            AppColors.transparent,
            AppColors.goldLight.withValues(alpha: alpha * 0.35),
            AppColors.goldLight.withValues(alpha: alpha),
            AppColors.transparent,
          ],
          const [0.0, 0.42, 0.58, 1.0],
        ),
      ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbShimmerPainter oldDelegate) {
    return (oldDelegate.sweep - sweep).abs() > 0.002 ||
        oldDelegate.intensity != intensity;
  }
}

class OrbShimmerLayer extends StatelessWidget {
  const OrbShimmerLayer({
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
        animation: motion.shimmerCycle,
        builder: (context, _) {
          return CustomPaint(
            painter: OrbShimmerPainter(
              context: OrbRenderContext.static(
                layoutSize: layoutSize,
                canvasSize: canvasSize,
              ),
              sweep: motion.shimmerSweep,
              intensity: intensity,
            ),
            size: Size.square(canvasSize),
          );
        },
      ),
    );
  }
}

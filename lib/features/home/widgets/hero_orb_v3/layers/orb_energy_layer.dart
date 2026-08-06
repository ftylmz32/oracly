/// OR-500 — Soft glowing golden light trails.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_animation.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

/// Heavily blurred comet trails — CW 35s / CCW 45s (motion unchanged).
class OrbEnergyPainter extends CustomPainter {
  OrbEnergyPainter({
    required this.context,
    this.intensity = 1,
  });

  final OrbRenderContext context;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = context.normOffset(OrbConstants.ringBandCenterNorm);
    final rx = context.normScalar(OrbConstants.ringBandRadiusXNorm);
    final ry = context.normScalar(OrbConstants.ringBandRadiusYNorm);
    final blur = OrbConstants.lightTrailBlurSigma;
    final sweep = OrbConstants.lightTrailSweepRadians;

    _drawLightTrail(
      canvas,
      center: center,
      rx: rx * OrbConstants.ringOuterScale,
      ry: ry * OrbConstants.ringOuterScale,
      headAngle: context.ringClockwiseAngle * pi * 2,
      sweep: sweep,
      clockwise: true,
      alpha: 0.16 * intensity,
      blur: blur,
    );

    _drawLightTrail(
      canvas,
      center: center + Offset(0, context.normScalar(0.012)),
      rx: rx * OrbConstants.ringInnerScale,
      ry: ry * OrbConstants.ringInnerScale,
      headAngle: -context.ringCounterClockwiseAngle * pi * 2,
      sweep: sweep * 0.88,
      clockwise: false,
      alpha: 0.12 * intensity,
      blur: blur * 1.35,
    );
  }

  void _drawLightTrail(
    Canvas canvas, {
    required Offset center,
    required double rx,
    required double ry,
    required double headAngle,
    required double sweep,
    required bool clockwise,
    required double alpha,
    required double blur,
  }) {
    final direction = clockwise ? 1.0 : -1.0;
    final tailAngle = headAngle - direction * sweep;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(rx, ry);

    final trailPaint = OrbPaint.aa(
      style: PaintingStyle.stroke,
      strokeWidth: 3.2 / rx,
      blendMode: BlendMode.plus,
      maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, blur / rx),
      shader: ui.Gradient.sweep(
        Offset.zero,
        [
          AppColors.transparent,
          AppColors.goldLight.withValues(alpha: alpha * 0.25),
          AppColors.goldLight.withValues(alpha: alpha * 0.70),
          AppColors.gold.withValues(alpha: alpha * 0.35),
          AppColors.transparent,
        ],
        _trailStops(headAngle, sweep, clockwise),
      ),
    );

    final ghostPaint = OrbPaint.aa(
      style: PaintingStyle.stroke,
      strokeWidth: 6.0 / rx,
      blendMode: BlendMode.plus,
      maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, (blur * 2.0) / rx),
      color: AppColors.goldLight.withValues(alpha: alpha * 0.10),
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 1),
      tailAngle,
      direction * sweep,
      false,
      trailPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 1),
      tailAngle,
      direction * sweep,
      false,
      ghostPaint,
    );

    canvas.drawCircle(
      Offset(cos(headAngle), sin(headAngle)),
      3.6 / rx,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, (blur * 0.9) / rx),
        color: AppColors.goldLight.withValues(alpha: alpha * 0.65),
      ),
    );

    canvas.restore();
  }

  List<double> _trailStops(double headAngle, double sweep, bool clockwise) {
    final headNorm = ((headAngle / (pi * 2)) % 1 + 1) % 1;
    final tailNorm = ((headNorm - (clockwise ? sweep : -sweep) / (pi * 2)) % 1 + 1) % 1;
    return [tailNorm, (tailNorm + headNorm) * 0.5 % 1, headNorm, (headNorm + 0.02) % 1, (headNorm + 0.06) % 1];
  }

  @override
  bool shouldRepaint(covariant OrbEnergyPainter oldDelegate) {
    return oldDelegate.context.ringClockwiseAngle != context.ringClockwiseAngle ||
        oldDelegate.context.ringCounterClockwiseAngle !=
            context.ringCounterClockwiseAngle ||
        oldDelegate.intensity != intensity;
  }
}

class OrbEnergyLayer extends StatelessWidget {
  const OrbEnergyLayer({
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
        animation: Listenable.merge([
          motion.ringClockwise,
          motion.ringCounterClockwise,
        ]),
        builder: (context, _) {
          return CustomPaint(
            painter: OrbEnergyPainter(
              intensity: intensity.clamp(0.0, 1.0),
              context: OrbRenderContext(
                  layoutSize: layoutSize,
                  canvasSize: canvasSize,
                  innerGlowOpacity: 1,
                  ringClockwiseAngle: motion.ringClockwiseAngle,
                  ringCounterClockwiseAngle: motion.ringCounterClockwiseAngle,
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

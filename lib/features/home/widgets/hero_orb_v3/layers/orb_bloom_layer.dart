/// OR-500 — Subtle HDR bloom halo.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';
/// Subtle bloom halo unifying sphere, pedestal, and golden light.
class OrbBloomPainter extends CustomPainter {
  const OrbBloomPainter({required this.context});

  final OrbRenderContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = OrbConstants.globalBloomStrength;
    final sphereCenter = context.sphereCenter;
    final sphereRadius = context.sphereRadius;
    final pedestalCenter = context.normOffset(OrbConstants.pedestalGlowCenterNorm);

    canvas.drawCircle(
      sphereCenter,
      sphereRadius * 1.20,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, sphereRadius * 0.15),
        shader: ui.Gradient.radial(
          sphereCenter,
          sphereRadius * 1.20,
          [
            AppColors.purpleLight.withValues(alpha: 0.07 * strength),
            AppColors.goldLight.withValues(alpha: 0.05 * strength),
            AppColors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
      ),
    );

    canvas.drawCircle(
      pedestalCenter,
      context.normScalar(OrbConstants.pedestalGlowRadiusNorm) * 1.08,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, sphereRadius * 0.11),
        shader: ui.Gradient.radial(
          pedestalCenter,
          context.normScalar(OrbConstants.pedestalGlowRadiusNorm) * 1.08,
          [
            AppColors.goldLight.withValues(alpha: 0.09 * strength),
            AppColors.gold.withValues(alpha: 0.045 * strength),
            AppColors.transparent,
          ],
          const [0.0, 0.48, 1.0],
        ),
      ),
    );

    final light = OrbConstants.lightDirectionNorm;
    canvas.drawCircle(
      sphereCenter + Offset(light.dx * sphereRadius, light.dy * sphereRadius),
      sphereRadius * 0.34,
      OrbPaint.aa(
        blendMode: BlendMode.softLight,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, sphereRadius * 0.09),
        shader: ui.Gradient.radial(
          sphereCenter + Offset(light.dx * sphereRadius, light.dy * sphereRadius),
          sphereRadius * 0.34,
          [
            AppColors.white.withValues(alpha: 0.06 * strength),
            AppColors.transparent,
          ],
          const [0.0, 1.0],
        ),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant OrbBloomPainter oldDelegate) => false;
}

class OrbBloomLayer extends StatelessWidget {
  const OrbBloomLayer({
    super.key,
    required this.layoutSize,
    required this.canvasSize,
  });

  final double layoutSize;
  final double canvasSize;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: OrbBloomPainter(
          context: OrbRenderContext.static(
            layoutSize: layoutSize,
            canvasSize: canvasSize,
          ),
        ),
        size: Size.square(canvasSize),
      ),
    );
  }
}

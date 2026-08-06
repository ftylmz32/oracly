/// OR-500 — Pedestal ambient bloom only (no center overlay).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

/// Pedestal golden bloom — kept away from the logo center.
class OrbGlowPainter extends CustomPainter {
  const OrbGlowPainter({required this.context});

  final OrbRenderContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = OrbConstants.goldenIlluminationStrength;
    final center = context.normOffset(OrbConstants.pedestalGlowCenterNorm);
    final radius = context.normScalar(OrbConstants.pedestalGlowRadiusNorm);

    canvas.drawCircle(
      center,
      radius,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        shader: ui.Gradient.radial(
          center,
          radius,
          [
            AppColors.goldLight.withValues(alpha: 0.13 * gold),
            AppColors.gold.withValues(alpha: 0.06 * gold),
            AppColors.transparent,
          ],
          const [0.0, 0.42, 1.0],
        ),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant OrbGlowPainter oldDelegate) => false;
}

class OrbGlowLayer extends StatelessWidget {
  const OrbGlowLayer({
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
        painter: OrbGlowPainter(
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

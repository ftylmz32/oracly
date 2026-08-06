/// OR-350 — Pedestal antique gold material enhancement.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_render_context.dart';

/// Specular metal response on pedestal — no geometry change.
class OrbPedestalPainter extends CustomPainter {
  const OrbPedestalPainter({required this.context});

  final OrbRenderContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final width = context.canvasSize;
    final topY = context.normScalar(OrbConstants.pedestalTopNorm);
    final bottomY = context.normScalar(OrbConstants.pedestalBottomNorm);
    final centerX = context.normScalar(0.5);

    final pedestalRect = Rect.fromLTRB(
      centerX - width * 0.22,
      topY,
      centerX + width * 0.22,
      bottomY,
    );

    canvas.save();
    canvas.clipRect(pedestalRect);

    canvas.drawRect(
      pedestalRect,
      Paint()
        ..blendMode = BlendMode.overlay
        ..shader = ui.Gradient.linear(
          Offset(centerX, topY),
          Offset(centerX, bottomY),
          [
            AppColors.goldLight.withValues(alpha: 0.14),
            const Color(0xFF8B6914).withValues(alpha: 0.18),
            const Color(0xFF3D2E0A).withValues(alpha: 0.22),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, topY + (bottomY - topY) * 0.18),
        width: width * 0.28,
        height: width * 0.04,
      ),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(
          Offset(centerX - width * 0.14, topY),
          Offset(centerX + width * 0.14, topY),
          [
            AppColors.transparent,
            AppColors.goldLight.withValues(alpha: 0.16),
            AppColors.goldLight.withValues(alpha: 0.22),
            AppColors.goldLight.withValues(alpha: 0.16),
            AppColors.transparent,
          ],
          const [0.0, 0.28, 0.50, 0.72, 1.0],
        ),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, bottomY - width * 0.02),
        width: width * 0.34,
        height: width * 0.05,
      ),
      Paint()
        ..blendMode = BlendMode.softLight
        ..shader = ui.Gradient.radial(
          Offset(centerX, bottomY - width * 0.02),
          width * 0.17,
          [
            AppColors.gold.withValues(alpha: 0.10),
            AppColors.transparent,
          ],
          const [0.0, 1.0],
        ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbPedestalPainter oldDelegate) => false;
}

class OrbPedestalLayer extends StatelessWidget {
  const OrbPedestalLayer({
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
        painter: OrbPedestalPainter(
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

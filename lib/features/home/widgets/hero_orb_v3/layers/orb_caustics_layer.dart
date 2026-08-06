/// OR-400 — Internal caustics + golden optical pools.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_render_context.dart';

/// Caustic light pools reinforcing optical depth and golden illumination.
class OrbCausticsPainter extends CustomPainter {
  const OrbCausticsPainter({required this.context});

  final OrbRenderContext context;

  static const List<(double u, double v, double scale, double alpha)> _lobes = [
    (0.12, 0.18, 0.14, 0.12),
    (-0.16, 0.10, 0.11, 0.10),
    (0.06, -0.08, 0.10, 0.09),
    (-0.08, -0.14, 0.12, 0.11),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final gold = OrbConstants.goldenIlluminationStrength;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    for (final (u, v, scale, alpha) in _lobes) {
      final lobeCenter = center + Offset(u * radius, v * radius);
      final lobeRadius = radius * scale;

      canvas.drawCircle(
        lobeCenter,
        lobeRadius,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, lobeRadius * 0.42)
          ..shader = ui.Gradient.radial(
            lobeCenter,
            lobeRadius,
            [
              AppColors.goldLight.withValues(alpha: alpha * gold),
              AppColors.gold.withValues(alpha: alpha * 0.40 * gold),
              AppColors.transparent,
            ],
            const [0.0, 0.42, 1.0],
          ),
      );
    }

    canvas.drawCircle(
      center + Offset(0, radius * 0.10),
      radius * 0.22,
      Paint()
        ..blendMode = BlendMode.softLight
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.08)
        ..shader = ui.Gradient.radial(
          center + Offset(0, radius * 0.10),
          radius * 0.22,
          [
            AppColors.purpleLight.withValues(alpha: 0.14),
            AppColors.transparent,
          ],
          const [0.0, 1.0],
        ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbCausticsPainter oldDelegate) => false;
}

class OrbCausticsLayer extends StatelessWidget {
  const OrbCausticsLayer({
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
        painter: OrbCausticsPainter(
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

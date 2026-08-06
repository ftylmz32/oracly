/// OR-046 — White Fresnel rim inside the crystal edge.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_physics.dart';

/// Thin white rim highlight along the inner edge of the sphere.
abstract final class OrbV2LayerFresnel {
  OrbV2LayerFresnel._();

  static void paint(OrbV2PaintContext ctx) {
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.sphereClip());

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center,
      radius: ctx.radius,
      centerAlignment: const Alignment(-0.88, -0.92),
      gradientRadius: 1.16,
      colors: [
        AppColors.transparent,
        AppColors.transparent,
        AppColors.white.withValues(alpha: 0.20),
        AppColors.white.withValues(alpha: 0.12),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.70, 0.82, 0.90, 1.0],
    );

    ctx.canvas.restore();
  }
}

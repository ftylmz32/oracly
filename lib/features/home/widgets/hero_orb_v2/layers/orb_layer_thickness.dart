/// OR-046 — Bottom internal shadow.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_physics.dart';

/// Darker bottom third inside the sphere — reference volumetric depth.
abstract final class OrbV2LayerThickness {
  OrbV2LayerThickness._();

  static void paint(OrbV2PaintContext ctx) {
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.sphereClip());

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center,
      radius: ctx.radius,
      centerAlignment: const Alignment(0.08, 0.70),
      gradientRadius: 0.76,
      colors: const [
        AppColors.transparent,
        Color(0x9912071F),
        Color(0xCC0B0615),
        Color(0xEE050208),
      ],
      stops: const [0.24, 0.60, 0.84, 1.0],
    );

    ctx.canvas.restore();
  }
}

/// OR-046 — Internal purple nebula.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_physics.dart';

/// Purple nebula volume inside the crystal shell.
abstract final class OrbV2LayerFog {
  OrbV2LayerFog._();

  static void paint(OrbV2PaintContext ctx) {
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.sphereClip());

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center + Offset(0, ctx.radius * 0.04),
      radius: ctx.radius * 0.80,
      centerAlignment: const Alignment(0.06, 0.18),
      colors: [
        AppColors.transparent,
        AppColors.purpleLight.withValues(alpha: 0.26),
        AppColors.purple.withValues(alpha: 0.36),
        AppColors.purpleDark.withValues(alpha: 0.44),
      ],
      stops: const [0.14, 0.44, 0.70, 1.0],
    );

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center,
      radius: ctx.radius * 0.52,
      centerAlignment: const Alignment(0.14, 0.26),
      colors: [
        AppColors.transparent,
        const Color(0x44FF8C42),
        AppColors.purpleLight.withValues(alpha: 0.16),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.24, 0.46, 1.0],
    );

    ctx.canvas.restore();
  }
}

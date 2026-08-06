/// OR-046 — Golden core nebula (reference interior energy).
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_physics.dart';

/// Warm golden glow, dark void, and stardust — as in the reference core.
abstract final class OrbV2LayerCore {
  OrbV2LayerCore._();

  static void paint(OrbV2PaintContext ctx) {
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.sphereClip());

    final strength = 0.90 + ctx.breathe * 0.10;

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center + Offset(0, ctx.radius * 0.10),
      radius: ctx.radius * 0.46,
      centerAlignment: const Alignment(0.04, 0.38),
      colors: [
        AppColors.goldLight.withValues(alpha: 0.62 * strength),
        const Color(0xFFFF8C42).withValues(alpha: 0.42 * strength),
        AppColors.gold.withValues(alpha: 0.20 * strength),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.30, 0.54, 1.0],
    );

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center,
      radius: ctx.radius * 0.22,
      colors: const [
        Color(0xFF030106),
        Color(0xAA0B0615),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.58, 1.0],
    );

    _paintStardust(ctx, strength);

    ctx.canvas.restore();
  }

  static void _paintStardust(OrbV2PaintContext ctx, double strength) {
    const seeds = [
      (0.06, -0.02, 0.007, 0.68),
      (-0.10, 0.05, 0.005, 0.54),
      (0.11, 0.08, 0.006, 0.60),
      (-0.05, 0.12, 0.005, 0.48),
      (0.03, -0.10, 0.005, 0.56),
    ];

    for (final (u, v, size, alpha) in seeds) {
      final pos = ctx.center + Offset(u * ctx.radius, v * ctx.radius);
      ctx.canvas.drawCircle(
        pos,
        ctx.radius * size,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: alpha * strength),
      );
    }
  }
}

/// OR-046 — Thick purple crystal shell (gradient volume, no wireframe).
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_physics.dart';

/// Perfect glass sphere with faceted purple shell via light gradients only.
abstract final class OrbV2LayerGlass {
  OrbV2LayerGlass._();

  static void paint(OrbV2PaintContext ctx) {
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.sphereClip());

    final rect = Rect.fromCircle(center: ctx.center, radius: ctx.radius);

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center,
      radius: ctx.radius,
      centerAlignment: const Alignment(-0.18, -0.22),
      focal: const Alignment(-0.38, -0.44),
      focalRadius: 0.08,
      gradientRadius: 0.98,
      colors: const [
        Color(0xCCF8F0FF),
        Color(0xCCB794FF),
        Color(0xB39B6DFF),
        Color(0xAA6B4BC4),
        Color(0xCC23153C),
        Color(0xE612071F),
        Color(0xF00B0615),
      ],
      stops: const [0.0, 0.12, 0.30, 0.48, 0.66, 0.84, 1.0],
    );

    ctx.canvas.drawCircle(
      ctx.center,
      ctx.radius,
      Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          colors: [
            AppColors.purpleDark.withValues(alpha: 0.18),
            AppColors.purpleLight.withValues(alpha: 0.24),
            AppColors.purple.withValues(alpha: 0.16),
            AppColors.purpleDark.withValues(alpha: 0.22),
            AppColors.purpleLight.withValues(alpha: 0.20),
            AppColors.purpleDark.withValues(alpha: 0.18),
          ],
          stops: const [0.0, 0.18, 0.36, 0.54, 0.72, 1.0],
          transform: GradientRotation(-0.35),
        ).createShader(rect),
    );

    orbV2DrawRadialGlow(
      ctx.canvas,
      center: ctx.center,
      radius: ctx.radius * 0.92,
      centerAlignment: const Alignment(0.12, 0.18),
      colors: [
        AppColors.transparent,
        AppColors.purple.withValues(alpha: 0.20),
        AppColors.primary.withValues(alpha: 0.34),
      ],
      stops: const [0.50, 0.78, 1.0],
    );

    ctx.canvas.restore();
  }
}

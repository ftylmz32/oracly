/// OR-046 — Top-left crystal reflections.
library;

import 'dart:math' show pi;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';

/// Specular highlights on the upper-left surface — reference lighting.
abstract final class OrbV2LayerReflections {
  OrbV2LayerReflections._();

  static void paint(OrbV2PaintContext ctx) {
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.sphereClip());

    _paintPrimaryReflection(ctx);
    _paintSecondaryStreak(ctx);
    _paintMicroSpecular(ctx);

    ctx.canvas.restore();
  }

  static void _paintPrimaryReflection(OrbV2PaintContext ctx) {
    final d = ctx.diameter;
    final topLeft = ctx.center - Offset(ctx.radius, ctx.radius);
    final sweep = d * 0.58;
    final glareTopLeft = topLeft + Offset(-d * 0.05, -d * 0.07);
    final glareCenter = glareTopLeft + Offset(sweep / 2, sweep / 2);

    ctx.canvas.drawRect(
      Rect.fromLTWH(glareTopLeft.dx, glareTopLeft.dy, sweep, sweep),
      orbV2RadialPaint(
        center: glareCenter,
        radius: sweep / 2,
        centerAlignment: const Alignment(-0.40, -0.46),
        gradientRadius: 0.90,
        colors: [
          AppColors.white.withValues(alpha: 0.42),
          AppColors.white.withValues(alpha: 0.20),
          AppColors.offWhite.withValues(alpha: 0.08),
          AppColors.transparent,
        ],
        stops: const [0.0, 0.28, 0.46, 1.0],
      ),
    );
  }

  static void _paintSecondaryStreak(OrbV2PaintContext ctx) {
    final d = ctx.diameter;
    final topLeft = ctx.center - Offset(ctx.radius, ctx.radius);
    final streakTopLeft = topLeft + Offset(d * 0.12, d * 0.22);
    final streakRect = Rect.fromLTWH(
      streakTopLeft.dx,
      streakTopLeft.dy,
      d * 0.44,
      d * 0.030,
    );

    ctx.canvas.save();
    ctx.canvas.translate(streakRect.center.dx, streakRect.center.dy);
    ctx.canvas.rotate(-pi * 0.18);
    ctx.canvas.translate(-streakRect.center.dx, -streakRect.center.dy);
    ctx.canvas.drawOval(
      streakRect,
      Paint()
        ..shader = ui.Gradient.linear(
          streakRect.topLeft,
          streakRect.topRight,
          [
            AppColors.transparent,
            AppColors.white.withValues(alpha: 0.06),
            AppColors.white.withValues(alpha: 0.26),
            AppColors.transparent,
          ],
          const [0.0, 0.30, 0.62, 1.0],
        ),
    );
    ctx.canvas.restore();
  }

  static void _paintMicroSpecular(OrbV2PaintContext ctx) {
    final d = ctx.diameter;
    final dot = d * 0.065;
    final topLeft = ctx.center - Offset(ctx.radius, ctx.radius);
    final dotTopLeft = topLeft + Offset(d * 0.16, d * 0.08);
    final dotCenter = dotTopLeft + Offset(dot / 2, dot / 2);

    ctx.canvas.drawCircle(
      dotCenter,
      dot / 2,
      orbV2RadialPaint(
        center: dotCenter,
        radius: dot / 2,
        colors: [
          AppColors.white.withValues(alpha: 0.90),
          AppColors.white.withValues(alpha: 0.40),
          AppColors.transparent,
        ],
        stops: const [0.0, 0.36, 1.0],
      ),
    );
  }
}

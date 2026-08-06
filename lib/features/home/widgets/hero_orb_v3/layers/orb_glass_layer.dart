/// OR-900 — Final glass optics polish (design frozen).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

/// Smooth thick crystal shell — Fresnel, refraction, logo-clear center.
class OrbGlassPainter extends CustomPainter {
  const OrbGlassPainter({required this.context});

  final OrbRenderContext context;

  @override
  void paint(Canvas canvas, Size size) {
    _softenFacets(canvas);
    _paintShellVolume(canvas);
    _paintCenterClearance(canvas);
    _paintRefraction(canvas);
    _paintFresnel(canvas);
    _paintSpecularReflections(canvas);
  }

  void _softenFacets(Canvas canvas) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final strength = OrbConstants.facetSofteningStrength;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    canvas.drawCircle(
      center,
      radius,
      OrbPaint.aa(
        blendMode: BlendMode.softLight,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.12),
        shader: RadialGradient(
          center: const Alignment(-0.10, -0.16),
          radius: 1.0,
          colors: [
            AppColors.offWhite.withValues(alpha: 0.14 * strength),
            AppColors.purpleLight.withValues(alpha: 0.20 * strength),
            AppColors.purple.withValues(alpha: 0.08 * strength),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.38, 0.70, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
      ),
    );

    canvas.drawCircle(
      center,
      radius * 0.97,
      OrbPaint.aa(
        blendMode: BlendMode.screen,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.17),
        shader: ui.Gradient.radial(
          center,
          radius * 0.97,
          [
            AppColors.offWhite.withValues(alpha: 0.08 * strength),
            AppColors.purpleLight.withValues(alpha: 0.10 * strength),
            AppColors.transparent,
          ],
          const [0.0, 0.52, 1.0],
        ),
      ),
    );

    canvas.restore();
  }

  void _paintShellVolume(Canvas canvas) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final shell = radius * OrbConstants.shellThicknessNorm;
    final innerR = radius * OrbConstants.shellInnerRadiusNorm;
    final depth = OrbConstants.opticalDepthStrength;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    canvas.drawCircle(
      center,
      radius,
      OrbPaint.aa(
        blendMode: BlendMode.srcOver,
        shader: ui.Gradient.radial(
          center,
          radius,
          [
            AppColors.transparent,
            AppColors.transparent,
            AppColors.purpleDark.withValues(alpha: 0.24 * depth),
            AppColors.purple.withValues(alpha: 0.36 * depth),
            AppColors.purpleDark.withValues(alpha: 0.20 * depth),
            AppColors.transparent,
          ],
          [
            0.0,
            innerR / radius - 0.04,
            innerR / radius,
            innerR / radius + shell / radius * 0.48,
            innerR / radius + shell / radius * 1.02,
            1.0,
          ],
        ),
      ),
    );

    canvas.restore();
  }

  void _paintCenterClearance(Canvas canvas) {
    final center = context.sphereCenter;
    final clearR = context.normScalar(OrbConstants.centerClearRadiusNorm);
    final boost = OrbConstants.glassTransparencyBoost;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    canvas.drawCircle(
      center,
      clearR * 1.6,
      OrbPaint.aa(
        blendMode: BlendMode.screen,
        shader: ui.Gradient.radial(
          center,
          clearR * 1.6,
          [
            AppColors.offWhite.withValues(alpha: 0.08 + boost * 0.12),
            AppColors.purpleLight.withValues(alpha: 0.04 + boost * 0.06),
            AppColors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
      ),
    );

    canvas.restore();
  }

  void _paintRefraction(Canvas canvas) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final light = OrbConstants.lightDirectionNorm;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    final bendCenter = center + Offset(light.dx * radius, light.dy * radius);
    canvas.drawCircle(
      bendCenter,
      radius * 0.95,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        shader: ui.Gradient.radial(
          bendCenter,
          radius * 0.95,
          [
            const Color(0x28B794FF),
            const Color(0x20F0D77A),
            const Color(0x14FFFFFF),
            AppColors.transparent,
          ],
          const [0.66, 0.80, 0.90, 1.0],
        ),
      ),
    );

    canvas.drawCircle(
      center + Offset(-light.dx * radius * 0.3, -light.dy * radius * 0.3),
      radius * 0.90,
      OrbPaint.aa(
        blendMode: BlendMode.softLight,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.04),
        shader: ui.Gradient.radial(
          center,
          radius * 0.90,
          [
            AppColors.purpleLight.withValues(alpha: 0.12),
            AppColors.transparent,
          ],
          const [0.74, 1.0],
        ),
      ),
    );

    canvas.restore();
  }

  void _paintFresnel(Canvas canvas) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final start = OrbConstants.fresnelStartNorm;
    final light = OrbConstants.lightDirectionNorm;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    canvas.drawCircle(
      center,
      radius,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        shader: RadialGradient(
          center: Alignment(light.dx, light.dy),
          radius: 1.0,
          colors: [
            AppColors.transparent,
            AppColors.transparent,
            AppColors.white.withValues(alpha: 0.22),
            AppColors.white.withValues(alpha: 0.48),
            AppColors.offWhite.withValues(alpha: 0.30),
            AppColors.transparent,
          ],
          stops: [0.0, start, start + 0.04, start + 0.08, start + 0.12, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
      ),
    );

    canvas.drawCircle(
      center,
      radius,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        shader: ui.Gradient.radial(
          center,
          radius,
          [
            AppColors.transparent,
            AppColors.transparent,
            AppColors.white.withValues(alpha: 0.28),
            AppColors.white.withValues(alpha: 0.14),
            AppColors.transparent,
          ],
          [0.0, 0.86, 0.93, 0.97, 1.0],
        ),
      ),
    );

    canvas.restore();
  }

  void _paintSpecularReflections(Canvas canvas) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final spec = OrbConstants.specularHighlightStrength;
    final light = OrbConstants.lightDirectionNorm;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    final glareCenter = center + Offset(light.dx * radius * 0.92, light.dy * radius * 0.92);
    final glareRadius = radius * 0.22;

    canvas.drawCircle(
      glareCenter,
      glareRadius,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, glareRadius * 0.20),
        shader: ui.Gradient.radial(
          glareCenter,
          glareRadius,
          [
            AppColors.white.withValues(alpha: 0.42 * spec),
            AppColors.white.withValues(alpha: 0.18 * spec),
            AppColors.transparent,
          ],
          const [0.0, 0.40, 1.0],
        ),
      ),
    );

    final streakCenter = center + Offset(light.dx * radius * 0.55, light.dy * radius * 0.62);
    canvas.drawOval(
      Rect.fromCenter(
        center: streakCenter,
        width: radius * 0.34,
        height: radius * 0.05,
      ),
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.016),
        shader: ui.Gradient.linear(
          streakCenter - Offset(radius * 0.17, 0),
          streakCenter + Offset(radius * 0.17, 0),
          [
            AppColors.transparent,
            AppColors.white.withValues(alpha: 0.14 * spec),
            AppColors.white.withValues(alpha: 0.32 * spec),
            AppColors.transparent,
          ],
          const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
    );

    final dotCenter = center + Offset(light.dx * radius * 0.72, light.dy * radius * 0.78);
    canvas.drawCircle(
      dotCenter,
      radius * 0.028,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        color: AppColors.white.withValues(alpha: 0.60 * spec),
      ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbGlassPainter oldDelegate) => false;
}

class OrbGlassLayer extends StatelessWidget {
  const OrbGlassLayer({
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
        painter: OrbGlassPainter(
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

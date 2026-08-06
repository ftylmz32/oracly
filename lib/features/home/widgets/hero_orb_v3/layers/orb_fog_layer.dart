/// OR-500 — Volumetric purple mist inside the sphere.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

/// Blurred volumetric purple nebula — no hard facet structure.
class OrbFogPainter extends CustomPainter {
  const OrbFogPainter({required this.context});

  final OrbRenderContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final center = context.sphereCenter;
    final radius = context.sphereRadius;
    final strength = OrbConstants.internalFogStrength;
    final mist = OrbConstants.volumetricMistStrength;
    final blur = radius * OrbConstants.nebulaBlurFactor;

    canvas.save();
    canvas.clipPath(context.sphereClip());

    _nebulaBlob(
      canvas,
      center: center + Offset(0, radius * 0.05),
      radius: radius * 0.86,
      focal: const Alignment(0.06, 0.18),
      blur: blur,
      colors: [
        AppColors.transparent,
        AppColors.purpleLight.withValues(alpha: 0.18 * strength),
        AppColors.purple.withValues(alpha: 0.28 * strength),
        AppColors.purpleDark.withValues(alpha: 0.32 * strength),
      ],
      stops: const [0.08, 0.36, 0.62, 1.0],
    );

    _nebulaBlob(
      canvas,
      center: center + Offset(-radius * 0.12, -radius * 0.06),
      radius: radius * 0.72,
      focal: const Alignment(-0.16, -0.08),
      blur: blur * 1.1,
      colors: [
        AppColors.purpleLight.withValues(alpha: 0.14 * strength),
        AppColors.purple.withValues(alpha: 0.22 * strength),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.44, 1.0],
    );

    _nebulaBlob(
      canvas,
      center: center + Offset(radius * 0.10, radius * 0.14),
      radius: radius * 0.62,
      focal: const Alignment(0.14, 0.26),
      blur: blur * 0.9,
      colors: [
        AppColors.transparent,
        const Color(0x44FF9A4D).withValues(alpha: 0.12 * strength),
        AppColors.purple.withValues(alpha: 0.16 * strength),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.28, 0.56, 1.0],
    );

    _nebulaBlob(
      canvas,
      center: center + Offset(0, radius * 0.08),
      radius: radius * 0.48,
      focal: Alignment.center,
      blur: blur * 1.25,
      colors: [
        AppColors.goldLight.withValues(alpha: 0.08 * strength),
        AppColors.purpleLight.withValues(alpha: 0.12 * strength),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.50, 1.0],
    );

    canvas.drawCircle(
      center,
      radius * 0.96,
      OrbPaint.aa(
        blendMode: BlendMode.softLight,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, blur * 1.5),
        shader: RadialGradient(
          center: const Alignment(-0.10, -0.14),
          radius: 1.0,
          colors: [
            AppColors.offWhite.withValues(alpha: 0.08 * strength),
            AppColors.purpleLight.withValues(alpha: 0.12 * strength),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.96)),
      ),
    );

    _nebulaBlob(
      canvas,
      center: center,
      radius: radius * 0.72,
      focal: Alignment.center,
      blur: blur * 1.35,
      colors: [
        AppColors.transparent,
        AppColors.purpleLight.withValues(alpha: 0.10 * mist),
        AppColors.purple.withValues(alpha: 0.08 * mist),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.40, 0.70, 1.0],
    );

    canvas.restore();
  }

  void _nebulaBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Alignment focal,
    required double blur,
    required List<Color> colors,
    required List<double> stops,
  }) {
    canvas.drawCircle(
      center,
      radius,
      OrbPaint.aa(
        blendMode: BlendMode.srcOver,
        maskFilter: ui.MaskFilter.blur(ui.BlurStyle.normal, blur),
        shader: RadialGradient(
          center: focal,
          radius: 1.0,
          colors: colors,
          stops: stops,
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant OrbFogPainter oldDelegate) => false;
}

class OrbFogLayer extends StatelessWidget {
  const OrbFogLayer({
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
        painter: OrbFogPainter(
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

/// OR-500 — Brighter, sharper metallic OR embedded in crystal.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';
import '../orb_paint.dart';
import '../orb_render_context.dart';

/// Crisp gold OR enhancement — reads above backlight, inside the glass.
class OrbLogoPainter extends CustomPainter {
  const OrbLogoPainter({required this.context});

  final OrbRenderContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final center = context.normOffset(OrbConstants.logoCenterNorm);
    final radius = context.normScalar(OrbConstants.logoRadiusNorm);
    final strength = OrbConstants.logoMetallicStrength;
    final light = OrbConstants.lightDirectionNorm;

    final logoClip = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(logoClip);

    canvas.drawCircle(
      center + Offset(0, radius * 0.10),
      radius * 0.95,
      OrbPaint.aa(
        blendMode: BlendMode.multiply,
        shader: ui.Gradient.radial(
          center + Offset(0, radius * 0.10),
          radius * 0.95,
          [
            AppColors.purpleDark.withValues(alpha: 0.16),
            AppColors.transparent,
          ],
          const [0.0, 1.0],
        ),
      ),
    );

    canvas.drawCircle(
      center,
      radius * 0.88,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        shader: ui.Gradient.radial(
          center,
          radius * 0.88,
          [
            AppColors.gold.withValues(alpha: 0.32 * strength),
            AppColors.goldLight.withValues(alpha: 0.48 * strength),
            AppColors.gold.withValues(alpha: 0.22 * strength),
            AppColors.transparent,
          ],
          const [0.0, 0.38, 0.62, 1.0],
        ),
      ),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(light.dx * radius * 0.18, light.dy * radius * 0.32),
        width: radius * 1.05,
        height: radius * 0.18,
      ),
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        shader: ui.Gradient.linear(
          Offset(center.dx - radius * 0.52, center.dy),
          Offset(center.dx + radius * 0.52, center.dy),
          [
            AppColors.transparent,
            AppColors.goldLight.withValues(alpha: 0.55 * strength),
            AppColors.white.withValues(alpha: 0.32 * strength),
            AppColors.transparent,
          ],
          const [0.0, 0.44, 0.56, 1.0],
        ),
      ),
    );

    canvas.drawCircle(
      center + Offset(-light.dx * radius * 0.15, -light.dy * radius * 0.12),
      radius * 0.08,
      OrbPaint.aa(
        blendMode: BlendMode.plus,
        color: AppColors.white.withValues(alpha: 0.35 * strength),
      ),
    );

    canvas.drawCircle(
      center,
      radius * 0.96,
      OrbPaint.aa(
        blendMode: BlendMode.softLight,
        style: PaintingStyle.stroke,
        strokeWidth: radius * 0.05,
        shader: ui.Gradient.radial(
          center,
          radius,
          [
            AppColors.goldLight.withValues(alpha: 0.28 * strength),
            AppColors.transparent,
          ],
          const [0.80, 1.0],
        ),
      ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbLogoPainter oldDelegate) => false;
}

class OrbLogoLayer extends StatelessWidget {
  const OrbLogoLayer({
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
        painter: OrbLogoPainter(
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

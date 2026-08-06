import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SpiritOrbBodyLayers {
  SpiritOrbBodyLayers._();

  static void paint(
    Canvas canvas,
    Offset c,
    double r, {
    required double coreGlow,
    required double hazeOpacity,
  }) {
    _atmosphericGlow(canvas, c, r);
    _volumetricHaze(canvas, c, r, hazeOpacity);
    _mainSphere(canvas, c, r);
    _luminousCore(canvas, c, r, coreGlow);
  }

  static void _atmosphericGlow(Canvas canvas, Offset c, double r) {
    for (final l in [
      (2.0, 0.018, 150.0, AppColors.orbGlow),
      (1.68, 0.035, 120.0, AppColors.primaryLight),
      (1.38, 0.07, 92.0, AppColors.primary),
      (1.12, 0.11, 64.0, AppColors.gold),
    ]) {
      canvas.drawCircle(
        c,
        r * l.$1,
        Paint()
          ..color = l.$4.withValues(alpha: l.$2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, l.$3),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * 0.88), width: r * 1.1, height: r * 0.12),
      Paint()..color = Colors.black.withValues(alpha: 0.16)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );
  }

  static void _volumetricHaze(Canvas canvas, Offset c, double r, double hazeOpacity) {
    canvas.drawCircle(
      c + Offset(-r * 0.12, -r * 0.18),
      r * 1.08,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.primaryLight.withValues(alpha: 0.14), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.08)),
    );
    canvas.drawCircle(
      c,
      r + 32,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: hazeOpacity * 0.55),
            AppColors.primary.withValues(alpha: hazeOpacity * 0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r + 32)),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
      c,
      r * 0.78,
      Paint()
        ..color = AppColors.orbCore.withValues(alpha: hazeOpacity * 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.restore();
  }

  static void _mainSphere(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.44),
          focal: const Alignment(-0.58, -0.58),
          focalRadius: 0.06,
          colors: [
            const Color(0xFFF8F0FF).withValues(alpha: 0.78),
            AppColors.orbCore.withValues(alpha: 0.92),
            AppColors.primaryLight.withValues(alpha: 0.96),
            AppColors.primary.withValues(alpha: 0.98),
            AppColors.primaryDark.withValues(alpha: 0.94),
            const Color(0xFF12082A).withValues(alpha: 0.99),
          ],
          stops: const [0.0, 0.14, 0.34, 0.56, 0.78, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c + Offset(r * 0.18, r * 0.24),
      r * 0.92,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0xFF08041A).withValues(alpha: 0.52)],
          stops: const [0.32, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..shader = SweepGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.04),
            AppColors.goldLight.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.16),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  static void _luminousCore(Canvas canvas, Offset c, double r, double coreGlow) {
    canvas.drawCircle(
      c,
      r * 0.18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: coreGlow),
            AppColors.goldLight.withValues(alpha: coreGlow * 0.92),
            AppColors.gold.withValues(alpha: coreGlow * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.28, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.18)),
    );
    canvas.drawCircle(c, r * 0.055, Paint()..color = Colors.white.withValues(alpha: coreGlow * 0.9));
  }
}

/// OR-1020 — Deck selection mystical orb painter.
library;

import 'dart:math' show cos, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Slower, deeper crystal orb — distinct from Tarot Home orb.
class TarotDeckOrbPainter extends CustomPainter {
  const TarotDeckOrbPainter({
    required this.glowPhase,
    required this.particlePhase,
  });

  final double glowPhase;
  final double particlePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.40;
    final pulse = 0.82 + glowPhase * 0.14;

    _haloRings(canvas, center, radius, pulse);
    _outerBloom(canvas, center, radius, pulse);
    _crystalBody(canvas, center, radius);
    _innerMist(canvas, center, radius * 0.78);
    _glassShell(canvas, center, radius);
    _highlights(canvas, center, radius);
    _motes(canvas, center, radius);
  }

  void _haloRings(Canvas canvas, Offset center, double radius, double pulse) {
    for (var i = 0; i < 3; i++) {
      final r = radius * (1.18 + i * 0.12) * pulse;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppColors.purpleLight.withValues(alpha: 0.06 + i * 0.03)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
      );
    }
  }

  void _outerBloom(Canvas canvas, Offset center, double radius, double pulse) {
    canvas.drawCircle(
      center,
      radius * 1.42 * pulse,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.32)
        ..shader = ui.Gradient.radial(
          center,
          radius * 1.42,
          [
            AppColors.purpleGlow.withValues(alpha: 0.26 * pulse),
            AppColors.goldGlow.withValues(alpha: 0.06 * pulse),
            AppColors.transparent,
          ],
          const [0.0, 0.50, 1.0],
        ),
    );
  }

  void _crystalBody(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center + Offset(-radius * 0.14, -radius * 0.18),
          radius * 1.08,
          [
            AppColors.purpleLight.withValues(alpha: 0.42),
            AppColors.purple.withValues(alpha: 0.78),
            const Color(0xFF2A1545),
            const Color(0xFF0E0618),
          ],
          const [0.0, 0.40, 0.74, 1.0],
        ),
    );
  }

  void _innerMist(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius * 0.92)));
    canvas.drawCircle(
      center + Offset(0, radius * 0.10),
      radius * 0.70,
      Paint()
        ..blendMode = BlendMode.softLight
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.22)
        ..shader = ui.Gradient.radial(
          center,
          radius * 0.70,
          [
            AppColors.transparent,
            AppColors.purpleLight.withValues(alpha: 0.22),
            AppColors.goldLight.withValues(alpha: 0.06),
            AppColors.transparent,
          ],
          const [0.0, 0.45, 0.62, 1.0],
        ),
    );
    canvas.restore();
  }

  void _glassShell(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          center + Offset(-radius * 0.30, -radius * 0.34),
          radius,
          [
            AppColors.transparent,
            AppColors.transparent,
            AppColors.white.withValues(alpha: 0.22),
            AppColors.transparent,
          ],
          const [0.0, 0.74, 0.90, 1.0],
        ),
    );
  }

  void _highlights(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center + Offset(-radius * 0.24, -radius * 0.30),
      radius * 0.14,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.05)
        ..color = AppColors.white.withValues(alpha: 0.36),
    );
  }

  void _motes(Canvas canvas, Offset center, double radius) {
    const seeds = <(double a, double d, double s)>[
      (0.5, 0.70, 1.2),
      (1.6, 0.76, 1.0),
      (2.8, 0.64, 1.4),
      (4.2, 0.80, 0.9),
      (5.5, 0.68, 1.1),
    ];
    for (final (a, d, s) in seeds) {
      final drift = particlePhase + a;
      final px = center.dx + cos(drift) * radius * d;
      final py = center.dy + sin(drift * 0.9) * radius * d * 0.85;
      canvas.drawCircle(
        Offset(px, py),
        s,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = AppColors.goldLight.withValues(alpha: 0.42),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TarotDeckOrbPainter oldDelegate) {
    return oldDelegate.glowPhase != glowPhase ||
        oldDelegate.particlePhase != particlePhase;
  }
}

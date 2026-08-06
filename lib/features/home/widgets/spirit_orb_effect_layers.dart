import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'orb_models.dart';

class SpiritOrbEffectLayers {
  SpiritOrbEffectLayers._();

  static void paint(
    Canvas canvas,
    Offset c,
    double r, {
    required double drift,
    required double ringAngle,
    required List<OrbWisp> wisps,
    required List<OrbParticle> particles,
  }) {
    _energyWisps(canvas, c, r, drift, wisps);
    _glassReflection(canvas, c, r);
    _celestialRing(canvas, c, r, ringAngle);
    _floatingParticles(canvas, c, r, drift, particles);
  }

  static void _energyWisps(Canvas canvas, Offset c, double r, double drift, List<OrbWisp> wisps) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.9)));
    for (final w in wisps) {
      final a = w.angle + drift * w.speed;
      canvas.save();
      canvas.translate(c.dx + math.cos(a) * r * w.radius, c.dy + math.sin(a) * r * w.radius * 0.6);
      canvas.rotate(a + math.pi / 2);
      final pulse = 0.55 + math.sin(drift * 2 + w.phase).abs() * 0.45;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * w.width, height: r * 0.07),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.goldLight.withValues(alpha: 0.22 * pulse),
              AppColors.primaryLight.withValues(alpha: 0.18 * pulse),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCenter(center: Offset.zero, width: r * w.width, height: r * 0.07)),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  static void _glassReflection(Canvas canvas, Offset c, double r) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.32, -r * 0.38), width: r * 0.78, height: r * 0.44),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.48),
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.1, -r * 0.5), width: r * 0.16, height: r * 0.09),
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );
    canvas.restore();
  }

  static void _celestialRing(Canvas canvas, Offset c, double r, double ringAngle) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(ringAngle);
    canvas.drawCircle(
      Offset.zero,
      r + 14,
      Paint()
        ..shader = SweepGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.0),
            AppColors.goldLight.withValues(alpha: 0.14),
            AppColors.gold.withValues(alpha: 0.06),
            AppColors.gold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r + 14))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    canvas.rotate(-0.35);
    canvas.drawCircle(
      Offset.zero,
      r + 22,
      Paint()
        ..color = AppColors.primaryLight.withValues(alpha: 0.025)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.28,
    );
    canvas.restore();
  }

  static void _floatingParticles(
    Canvas canvas,
    Offset c,
    double r,
    double drift,
    List<OrbParticle> particles,
  ) {
    for (final p in particles.where((e) => e.orbit)) {
      final col = p.gold ? AppColors.goldLight : AppColors.primaryLight;
      final a = 0.12 + math.sin(drift * p.speed + p.phase).abs() * 0.2;
      canvas.drawCircle(
        Offset(
          c.dx + math.cos(drift * p.speed + p.phase) * r * p.dy,
          c.dy + math.sin(drift * p.speed + p.phase) * r * p.dy,
        ),
        p.size,
        Paint()..color = col.withValues(alpha: a),
      );
    }
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.88)));
    for (final p in particles.where((e) => !e.orbit)) {
      final col = p.gold ? AppColors.goldLight : Colors.white;
      final a = 0.1 + math.sin(drift * p.speed + p.phase).abs() * 0.14;
      canvas.drawCircle(
        Offset(
          c.dx + p.dx * r * 0.7 + math.sin(drift * p.speed + p.phase) * 7,
          c.dy + p.dy * r * 0.7 + math.cos(drift * p.speed + p.phase) * 6,
        ),
        p.size * 0.7,
        Paint()..color = col.withValues(alpha: a),
      );
    }
    canvas.restore();
  }
}

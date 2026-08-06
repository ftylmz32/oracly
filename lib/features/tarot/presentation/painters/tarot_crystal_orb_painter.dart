/// OR-1010 / OR-400 — Tarot-specific crystal orb painter.

library;



import 'dart:math' show cos, pi, sin;

import 'dart:ui' as ui;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_colors.dart';



class TarotCrystalOrbPainter extends CustomPainter {

  const TarotCrystalOrbPainter({

    required this.glowPhase,

    required this.particlePhase,

  });



  final double glowPhase;

  final double particlePhase;



  @override

  void paint(Canvas canvas, Size size) {

    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.shortestSide * 0.42;

    final pulse = 0.90 + glowPhase * 0.10;



    _outerBloom(canvas, center, radius, pulse);

    _goldBloom(canvas, center, radius, pulse);

    _crystalBody(canvas, center, radius);

    _innerNebula(canvas, center, radius * 0.72);

    _glassShell(canvas, center, radius);

    _rimLight(canvas, center, radius);

    _highlights(canvas, center, radius);

    _energyWisps(canvas, center, radius);

    _orbitParticles(canvas, center, radius);

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

            AppColors.purple.withValues(alpha: 0.12 * pulse),

            AppColors.transparent,

          ],

          const [0.0, 0.48, 1.0],

        ),

    );

  }



  void _goldBloom(Canvas canvas, Offset center, double radius, double pulse) {

    canvas.drawCircle(

      center + Offset(0, radius * 0.06),

      radius * 1.12 * pulse,

      Paint()

        ..blendMode = BlendMode.softLight

        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.22)

        ..shader = ui.Gradient.radial(

          center,

          radius * 1.1,

          [

            AppColors.transparent,

            AppColors.goldGlow.withValues(alpha: 0.14 * pulse),

            AppColors.transparent,

          ],

          const [0.0, 0.55, 1.0],

        ),

    );

  }



  void _crystalBody(Canvas canvas, Offset center, double radius) {

    canvas.drawCircle(

      center,

      radius,

      Paint()

        ..shader = ui.Gradient.radial(

          center + Offset(-radius * 0.14, -radius * 0.16),

          radius * 1.08,

          [

            AppColors.purpleLight.withValues(alpha: 0.62),

            AppColors.purple.withValues(alpha: 0.86),

            AppColors.purpleDark.withValues(alpha: 0.96),

            const Color(0xFF12071F),

          ],

          const [0.0, 0.32, 0.68, 1.0],

        ),

    );

  }



  void _glassShell(Canvas canvas, Offset center, double radius) {

    canvas.save();

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));



    // Soft caustic sweep

    canvas.drawCircle(

      center,

      radius,

      Paint()

        ..blendMode = BlendMode.plus

        ..shader = ui.Gradient.radial(

          center + Offset(-radius * 0.30, -radius * 0.34),

          radius * 1.05,

          [

            AppColors.transparent,

            AppColors.transparent,

            AppColors.white.withValues(alpha: 0.32),

            AppColors.white.withValues(alpha: 0.10),

            AppColors.transparent,

          ],

          const [0.0, 0.68, 0.86, 0.94, 1.0],

        ),

    );



    // Gold rim refraction

    canvas.drawCircle(

      center,

      radius * 0.97,

      Paint()

        ..style = PaintingStyle.stroke

        ..strokeWidth = radius * 0.035

        ..blendMode = BlendMode.softLight

        ..shader = ui.Gradient.sweep(

          center,

          [

            AppColors.transparent,

            AppColors.goldLight.withValues(alpha: 0.28),

            AppColors.transparent,

            AppColors.gold.withValues(alpha: 0.18),

            AppColors.transparent,

          ],

          const [0.0, 0.22, 0.5, 0.72, 1.0],

        ),

    );



    canvas.restore();

  }



  void _innerNebula(Canvas canvas, Offset center, double radius) {

    canvas.drawCircle(

      center + Offset(0, radius * 0.06),

      radius,

      Paint()

        ..blendMode = BlendMode.softLight

        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.38)

        ..shader = ui.Gradient.radial(

          center,

          radius,

          [

            AppColors.transparent,

            AppColors.purpleLight.withValues(alpha: 0.22),

            AppColors.goldLight.withValues(alpha: 0.10),

            AppColors.transparent,

          ],

          const [0.0, 0.38, 0.58, 1.0],

        ),

    );

  }



  void _rimLight(Canvas canvas, Offset center, double radius) {

    canvas.drawArc(

      Rect.fromCircle(center: center, radius: radius * 0.99),

      pi * 0.15,

      pi * 0.7,

      false,

      Paint()

        ..style = PaintingStyle.stroke

        ..strokeWidth = radius * 0.025

        ..blendMode = BlendMode.plus

        ..color = AppColors.goldLight.withValues(alpha: 0.22),

    );

  }



  void _highlights(Canvas canvas, Offset center, double radius) {

    final glare = center + Offset(-radius * 0.24, -radius * 0.30);

    canvas.drawCircle(

      glare,

      radius * 0.16,

      Paint()

        ..blendMode = BlendMode.plus

        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.05)

        ..color = AppColors.white.withValues(alpha: 0.48),

    );

    canvas.drawCircle(

      glare + Offset(radius * 0.06, radius * 0.08),

      radius * 0.05,

      Paint()

        ..blendMode = BlendMode.plus

        ..color = AppColors.white.withValues(alpha: 0.65),

    );

  }



  void _energyWisps(Canvas canvas, Offset center, double radius) {

    final wisp = Paint()

      ..style = PaintingStyle.stroke

      ..strokeWidth = 0.8

      ..blendMode = BlendMode.plus

      ..color = AppColors.goldLight.withValues(alpha: 0.12);



    for (var i = 0; i < 3; i++) {

      final a = particlePhase * 0.4 + i * 2.1;

      final path = Path()

        ..moveTo(

          center.dx + cos(a) * radius * 0.35,

          center.dy + sin(a) * radius * 0.35,

        )

        ..quadraticBezierTo(

          center.dx + cos(a + 0.4) * radius * 0.55,

          center.dy + sin(a + 0.4) * radius * 0.55 - 4,

          center.dx + cos(a + 0.8) * radius * 0.42,

          center.dy + sin(a + 0.8) * radius * 0.42,

        );

      canvas.drawPath(path, wisp);

    }

  }



  void _orbitParticles(Canvas canvas, Offset center, double radius) {

    const seeds = <(double angle, double dist, double size)>[

      (0.4, 0.72, 1.4),

      (1.8, 0.78, 1.0),

      (3.2, 0.68, 1.2),

      (4.6, 0.82, 0.9),

      (5.4, 0.74, 1.1),

      (6.2, 0.66, 0.8),

    ];



    for (final (angle, dist, dot) in seeds) {

      final drift = particlePhase + angle;

      final px = center.dx + cos(drift) * radius * dist;

      final py = center.dy + sin(drift * 1.08) * radius * dist * 0.88;

      canvas.drawCircle(

        Offset(px, py),

        dot,

        Paint()

          ..blendMode = BlendMode.plus

          ..color = AppColors.goldLight.withValues(alpha: 0.42),

      );

    }

  }



  @override

  bool shouldRepaint(covariant TarotCrystalOrbPainter oldDelegate) {

    return oldDelegate.glowPhase != glowPhase ||

        oldDelegate.particlePhase != particlePhase;

  }

}



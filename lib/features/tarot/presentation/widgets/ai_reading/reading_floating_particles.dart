/// OR-301+ — Sparse screen-level particles (max 10, very subtle).

library;



import 'dart:math' show cos, pi, sin;



import 'package:flutter/material.dart';



import '../../../../../core/theme/app_colors.dart';



class ReadingFloatingParticles extends StatelessWidget {

  const ReadingFloatingParticles({

    super.key,

    required this.phase,

    this.intensity = 1,

  });



  final double phase;

  final double intensity;



  @override

  Widget build(BuildContext context) {

    return Positioned.fill(

      child: RepaintBoundary(

        child: IgnorePointer(

          child: CustomPaint(

            painter: _FloatingParticlesPainter(

              phase: phase,

              intensity: intensity,

            ),

          ),

        ),

      ),

    );

  }

}



class _FloatingParticlesPainter extends CustomPainter {

  _FloatingParticlesPainter({required this.phase, required this.intensity});



  final double phase;

  final double intensity;



  static const _particles = <(double x, double y, double size, int tone)>[

    (0.12, 0.18, 0.9, 0),

    (0.28, 0.08, 0.7, 1),

    (0.55, 0.14, 0.8, 2),

    (0.78, 0.22, 0.65, 0),

    (0.88, 0.42, 0.75, 1),

    (0.15, 0.52, 0.85, 2),

    (0.42, 0.68, 0.7, 0),

    (0.68, 0.58, 0.8, 1),

    (0.32, 0.82, 0.6, 2),

    (0.82, 0.78, 0.72, 0),

  ];



  static const _tones = [

    AppColors.goldLight,

    AppColors.purpleLight,

    AppColors.white,

  ];



  @override

  void paint(Canvas canvas, Size size) {

    for (var i = 0; i < _particles.length; i++) {

      final (x, y, r, tone) = _particles[i];

      final driftX = sin(phase * pi * 2 + i * 0.9) * 4;

      final driftY = cos(phase * pi * 2 * 0.7 + i * 1.1) * 3;

      final tw = 0.35 + sin(phase * pi * 2 * 1.3 + i) * 0.25;

      canvas.drawCircle(

        Offset(size.width * x + driftX, size.height * y + driftY),

        r,

        Paint()

          ..color = _tones[tone].withValues(alpha: tw * 0.16 * intensity),

      );

    }

  }



  @override

  bool shouldRepaint(covariant _FloatingParticlesPainter old) =>

      old.phase != phase || old.intensity != intensity;

}



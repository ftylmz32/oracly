/// OR-1060 — Living mystical reading background.

library;



import 'dart:math' show cos, pi, sin;

import 'dart:ui';



import 'package:flutter/material.dart';



import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';



class ReadingBackground extends StatefulWidget {

  const ReadingBackground({

    super.key,

    required this.fogIntensity,

    this.phase = 0,

  });



  final double fogIntensity;

  final double phase;



  @override

  State<ReadingBackground> createState() => _ReadingBackgroundState();

}



class _ReadingBackgroundState extends State<ReadingBackground> {

  @override

  Widget build(BuildContext context) {

    final t = widget.phase;

    final breath = 0.5 + sin(t * pi * 2) * 0.5;

    final fog = widget.fogIntensity;

    final w = MediaQuery.sizeOf(context).width;



    return RepaintBoundary(

      child: Stack(

        fit: StackFit.expand,

        children: [

          const DecoratedBox(decoration: OraclySignatureChamber.reveal),

          _NebulaBlob(

            top: 90 + sin(t * pi * 2) * 6,

            left: w * 0.08 + cos(t * pi * 2 * 0.3) * 12,

            size: 260 + breath * 16,

            color: AppColors.purpleDark.withValues(alpha: 0.22 * fog),

            blur: 88,

          ),

          _NebulaBlob(

            top: 180 + cos(t * pi * 2 * 0.5) * 10,

            right: -30 + sin(t * pi * 2 * 0.4) * 8,

            size: 220 + breath * 14,

            color: AppColors.purple.withValues(alpha: 0.14 * fog),

            blur: 76,

          ),

          _NebulaBlob(

            bottom: 40 + sin(t * pi * 2 * 0.6) * 8,

            left: w * 0.35,

            size: 300 + breath * 18,

            color: const Color(0xFF2A1048).withValues(alpha: 0.18 * fog),

            blur: 92,

          ),

          _FogLayer(

            phase: t,

            intensity: fog,

            yFactor: 0.35,

            color: AppColors.purpleLight.withValues(alpha: 0.06 * fog),

          ),

          _FogLayer(

            phase: t + 0.35,

            intensity: fog,

            yFactor: 0.62,

            color: AppColors.gold.withValues(alpha: 0.035 * fog),

          ),

          Positioned.fill(
            child: CustomPaint(
              painter: _DistantStars(phase: t, intensity: fog),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _MagicSpecks(phase: t, intensity: fog),
            ),
          ),

          Positioned.fill(

            child: DecoratedBox(

              decoration: BoxDecoration(

                gradient: RadialGradient(

                  center: Alignment(

                    sin(t * pi * 2 * 0.25) * 0.15,

                    -0.15 + cos(t * pi * 2 * 0.2) * 0.08,

                  ),

                  radius: 1.15,

                  colors: [

                    AppColors.transparent,

                    Colors.black.withValues(alpha: 0.46),

                  ],

                  stops: const [0.52, 1.0],

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _NebulaBlob extends StatelessWidget {

  const _NebulaBlob({

    this.top,

    this.bottom,

    this.left,

    this.right,

    required this.size,

    required this.color,

    required this.blur,

  });



  final double? top;

  final double? bottom;

  final double? left;

  final double? right;

  final double size;

  final Color color;

  final double blur;



  @override

  Widget build(BuildContext context) {

    return Positioned(

      top: top,

      bottom: bottom,

      left: left,

      right: right,

      child: IgnorePointer(

        child: ImageFiltered(

          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),

          child: Container(

            width: size,

            height: size,

            decoration: BoxDecoration(shape: BoxShape.circle, color: color),

          ),

        ),

      ),

    );

  }

}



class _FogLayer extends StatelessWidget {

  const _FogLayer({

    required this.phase,

    required this.intensity,

    required this.yFactor,

    required this.color,

  });



  final double phase;

  final double intensity;

  final double yFactor;

  final Color color;



  @override

  Widget build(BuildContext context) {

    final h = MediaQuery.sizeOf(context).height;

    final w = MediaQuery.sizeOf(context).width;

    return Positioned(

      top: h * yFactor + sin(phase * pi * 2) * 10,

      left: -40 + cos(phase * pi * 2 * 0.7) * 20,

      child: IgnorePointer(

        child: ImageFiltered(

          imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),

          child: Container(

            width: w * 0.85,

            height: 120,

            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(80),

              color: color,

            ),

          ),

        ),

      ),

    );

  }

}



class _DistantStars extends CustomPainter {

  const _DistantStars({required this.phase, required this.intensity});



  final double phase;

  final double intensity;



  static const _stars = <(double x, double y, double r)>[

    (0.06, 0.11, 0.55),

    (0.14, 0.07, 0.45),

    (0.22, 0.19, 0.5),

    (0.31, 0.05, 0.4),

    (0.44, 0.12, 0.55),

    (0.58, 0.08, 0.48),

    (0.67, 0.16, 0.42),

    (0.76, 0.06, 0.52),

    (0.84, 0.14, 0.46),

    (0.92, 0.09, 0.5),

    (0.11, 0.31, 0.44),

    (0.38, 0.28, 0.5),

    (0.52, 0.34, 0.42),

    (0.71, 0.29, 0.48),

    (0.89, 0.33, 0.45),

    (0.18, 0.47, 0.5),

    (0.47, 0.51, 0.42),

    (0.63, 0.44, 0.46),

    (0.81, 0.49, 0.44),

    (0.29, 0.63, 0.48),

    (0.56, 0.67, 0.42),

    (0.74, 0.61, 0.5),

    (0.09, 0.78, 0.45),

    (0.41, 0.82, 0.48),

    (0.68, 0.76, 0.44),

    (0.87, 0.84, 0.46),

  ];



  @override

  void paint(Canvas canvas, Size size) {

    for (var i = 0; i < _stars.length; i++) {

      final (x, y, r) = _stars[i];

      final tw = 0.35 + sin(phase * pi * 2 * 0.35 + i * 0.7) * 0.25;

      canvas.drawCircle(

        Offset(size.width * x, size.height * y),

        r,

        Paint()

          ..color = AppColors.white.withValues(alpha: tw * 0.35 * intensity),

      );

    }

  }



  @override

  bool shouldRepaint(covariant _DistantStars old) =>

      old.phase != phase || old.intensity != intensity;

}



class _MagicSpecks extends CustomPainter {

  const _MagicSpecks({required this.phase, required this.intensity});



  final double phase;

  final double intensity;



  static const _specks = <(double x, double y)>[

    (0.2, 0.24),

    (0.48, 0.18),

    (0.72, 0.38),

    (0.34, 0.56),

    (0.61, 0.72),

  ];



  @override

  void paint(Canvas canvas, Size size) {

    for (var i = 0; i < _specks.length; i++) {

      final (x, y) = _specks[i];

      final gate = sin(phase * pi * 2 + i * 1.7);

      if (gate < 0.55) continue;

      final alpha = ((gate - 0.55) / 0.45).clamp(0.0, 1.0) * 0.28;

      final drift = sin(phase * pi * 2 + i) * 3;

      canvas.drawCircle(

        Offset(size.width * x + drift, size.height * y),

        1.1,

        Paint()

          ..color = AppColors.goldLight.withValues(alpha: alpha * intensity),

      );

    }

  }



  @override

  bool shouldRepaint(covariant _MagicSpecks old) =>

      old.phase != phase || old.intensity != intensity;

}


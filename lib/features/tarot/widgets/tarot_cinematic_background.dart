/// OR-1021 — Cinematic tarot background — nebula, stars, vignette.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';

class TarotCinematicBackground extends StatefulWidget {
  const TarotCinematicBackground({super.key, required this.child});

  final Widget child;

  @override
  State<TarotCinematicBackground> createState() =>
      _TarotCinematicBackgroundState();
}

class _TarotCinematicBackgroundState extends State<TarotCinematicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 52),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (_, child) {
        final t = _motion.value;
        final breath = 0.04 + sin(t * pi * 2) * 0.018;
        return Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.background),
              child: SizedBox.expand(),
            ),
            _NebulaWash(
              top: 60 + sin(t * pi * 2) * 10,
              left: -70,
              size: 300,
              color: AppColors.purpleDark.withValues(alpha: 0.16 + breath),
            ),
            _NebulaWash(
              top: 220 + sin(t * pi * 2 + 1.2) * 14,
              right: -90,
              size: 340,
              color: AppColors.purple.withValues(alpha: 0.12 + breath * 0.8),
            ),
            _NebulaWash(
              bottom: 80,
              left: 20,
              size: 260,
              color: AppColors.gold.withValues(alpha: 0.04 + breath * 0.5),
            ),
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight.withValues(alpha: breath),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: breath * 0.5),
                    ),
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _GalaxyDustPainter(phase: t),
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _DistantStarsPainter(phase: t),
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _TarotConstellations(phase: t),
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _TarotStars(t),
                size: Size.infinite,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.15,
                      colors: [
                        AppColors.transparent,
                        Colors.black.withValues(alpha: 0.38),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.purpleDark.withValues(alpha: 0.08),
                        AppColors.transparent,
                        Colors.black.withValues(alpha: 0.12),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _NebulaWash extends StatelessWidget {
  const _NebulaWash({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 78, sigmaY: 78),
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

class _GalaxyDustPainter extends CustomPainter {
  const _GalaxyDustPainter({required this.phase});

  final double phase;

  static const _specks = <(double x, double y, double a)>[
    (0.04, 0.08, 0.06),
    (0.11, 0.22, 0.05),
    (0.19, 0.15, 0.07),
    (0.27, 0.31, 0.04),
    (0.33, 0.44, 0.06),
    (0.41, 0.19, 0.05),
    (0.48, 0.58, 0.04),
    (0.55, 0.36, 0.06),
    (0.63, 0.72, 0.05),
    (0.71, 0.28, 0.04),
    (0.78, 0.48, 0.06),
    (0.84, 0.66, 0.05),
    (0.91, 0.38, 0.04),
    (0.96, 0.82, 0.05),
    (0.08, 0.56, 0.04),
    (0.16, 0.74, 0.06),
    (0.24, 0.88, 0.05),
    (0.52, 0.92, 0.04),
    (0.68, 0.08, 0.05),
    (0.88, 0.14, 0.06),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _specks.length; i++) {
      final (x, y, a) = _specks[i];
      final drift = sin(phase * pi * 2 + i * 0.4) * 0.008;
      canvas.drawCircle(
        Offset(size.width * (x + drift), size.height * y),
        0.55,
        Paint()..color = AppColors.purpleLight.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyDustPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _DistantStarsPainter extends CustomPainter {
  const _DistantStarsPainter({required this.phase});

  final double phase;

  static const _stars = <(double x, double y, double r, double a)>[
    (0.03, 0.05, 0.35, 0.10),
    (0.09, 0.11, 0.30, 0.08),
    (0.14, 0.03, 0.40, 0.11),
    (0.21, 0.19, 0.32, 0.09),
    (0.29, 0.07, 0.38, 0.10),
    (0.37, 0.24, 0.30, 0.08),
    (0.46, 0.11, 0.35, 0.09),
    (0.53, 0.29, 0.32, 0.08),
    (0.61, 0.05, 0.40, 0.11),
    (0.69, 0.21, 0.30, 0.09),
    (0.76, 0.09, 0.38, 0.10),
    (0.83, 0.27, 0.32, 0.08),
    (0.90, 0.04, 0.35, 0.09),
    (0.95, 0.19, 0.30, 0.08),
    (0.07, 0.41, 0.32, 0.09),
    (0.17, 0.49, 0.35, 0.08),
    (0.28, 0.63, 0.30, 0.07),
    (0.39, 0.71, 0.38, 0.10),
    (0.51, 0.81, 0.32, 0.08),
    (0.64, 0.91, 0.35, 0.09),
    (0.73, 0.76, 0.30, 0.08),
    (0.86, 0.84, 0.38, 0.10),
    (0.92, 0.62, 0.32, 0.08),
    (0.12, 0.93, 0.35, 0.09),
    (0.44, 0.96, 0.30, 0.07),
    (0.58, 0.52, 0.32, 0.08),
    (0.66, 0.44, 0.35, 0.09),
    (0.80, 0.58, 0.30, 0.08),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final (x, y, r, a) = _stars[i];
      final tw = 0.6 + sin(phase * pi * 2 + i * 0.55) * 0.4;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        Paint()..color = Colors.white.withValues(alpha: a * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DistantStarsPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _TarotConstellations extends CustomPainter {
  const _TarotConstellations({required this.phase});

  final double phase;

  static const _groups = <List<(double x, double y)>>[
    [(0.12, 0.18), (0.16, 0.22), (0.20, 0.19), (0.18, 0.14)],
    [(0.78, 0.12), (0.82, 0.16), (0.86, 0.13), (0.84, 0.08)],
    [(0.08, 0.62), (0.12, 0.58), (0.15, 0.64), (0.11, 0.68)],
    [(0.72, 0.72), (0.76, 0.68), (0.80, 0.74), (0.77, 0.78)],
    [(0.44, 0.08), (0.48, 0.12), (0.52, 0.09)],
    [(0.58, 0.86), (0.62, 0.82), (0.66, 0.86), (0.63, 0.90)],
    [(0.32, 0.38), (0.36, 0.42), (0.40, 0.39)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..strokeWidth = 0.42
      ..style = PaintingStyle.stroke;

    final starPaint = Paint();

    for (var g = 0; g < _groups.length; g++) {
      final group = _groups[g];
      final twinkle = 0.5 + sin(phase * pi * 2 + g * 0.65) * 0.28;
      linePaint.color = AppColors.purpleLight.withValues(alpha: 0.07 * twinkle);

      for (var i = 0; i < group.length; i++) {
        final (x, y) = group[i];
        final point = Offset(size.width * x, size.height * y);
        starPaint.color = AppColors.white.withValues(alpha: 0.14 * twinkle);
        canvas.drawCircle(point, 0.85, starPaint);

        if (i > 0) {
          final (px, py) = group[i - 1];
          canvas.drawLine(
            Offset(size.width * px, size.height * py),
            point,
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TarotConstellations oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _TarotStars extends CustomPainter {
  _TarotStars(this.t);
  final double t;

  static const _positions = <(double x, double y, double r, double a)>[
    (0.05, 0.10, 0.7, 0.22),
    (0.18, 0.06, 0.5, 0.18),
    (0.31, 0.14, 0.8, 0.24),
    (0.67, 0.05, 0.6, 0.20),
    (0.91, 0.18, 0.9, 0.26),
    (0.24, 0.34, 0.5, 0.16),
    (0.56, 0.30, 0.7, 0.21),
    (0.88, 0.38, 0.6, 0.19),
    (0.14, 0.52, 0.8, 0.23),
    (0.42, 0.48, 0.5, 0.17),
    (0.74, 0.56, 0.7, 0.22),
    (0.08, 0.78, 0.6, 0.18),
    (0.36, 0.82, 0.9, 0.25),
    (0.62, 0.74, 0.5, 0.16),
    (0.92, 0.88, 0.7, 0.20),
    (0.50, 0.16, 0.6, 0.19),
    (0.22, 0.68, 0.55, 0.17),
    (0.78, 0.46, 0.75, 0.21),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _positions.length; i++) {
      final (x, y, r, a) = _positions[i];
      final tw = 0.72 + sin(t * pi * 2 + i) * 0.28;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        Paint()..color = Colors.white.withValues(alpha: a * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TarotStars old) => old.t != t;
}

/// Reference dream screen — dark gradient, stars, geometry, particles.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_gradients.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';

/// Mystical dream atmosphere — matches reference background layers.
class DreamReferenceBackground extends StatefulWidget {
  const DreamReferenceBackground({super.key, required this.child});

  final Widget child;

  @override
  State<DreamReferenceBackground> createState() =>
      _DreamReferenceBackgroundState();
}

class _DreamReferenceBackgroundState extends State<DreamReferenceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 52),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _motion, rest: 0.18);
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
            _Nebula(
              top: 60 + sin(t * pi * 2) * 10,
              left: -70,
              size: 300,
              color: AppColors.purpleDark.withValues(alpha: 0.16 + breath),
            ),
            _Nebula(
              top: 220 + sin(t * pi * 2 + 1.2) * 14,
              right: -90,
              size: 340,
              color: AppColors.purple.withValues(alpha: 0.12 + breath * 0.8),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _DreamStarsPainter(phase: t),
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _DreamSacredGeometryPainter(phase: t),
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _DreamParticlesPainter(phase: t),
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
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _Nebula extends StatelessWidget {
  const _Nebula({
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final blur = OraclyQuietMotion.still(context) ? 28.0 : 78.0;
    return Positioned(
      top: top,
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

class _DreamStarsPainter extends CustomPainter {
  const _DreamStarsPainter({required this.phase});

  final double phase;

  static const _stars = <(double x, double y, double r, double a)>[
    (0.05, 0.08, 0.35, 0.10),
    (0.14, 0.04, 0.30, 0.08),
    (0.24, 0.16, 0.38, 0.11),
    (0.36, 0.06, 0.32, 0.09),
    (0.48, 0.20, 0.35, 0.10),
    (0.62, 0.08, 0.30, 0.08),
    (0.74, 0.18, 0.38, 0.10),
    (0.86, 0.05, 0.32, 0.09),
    (0.12, 0.42, 0.35, 0.08),
    (0.28, 0.58, 0.30, 0.07),
    (0.52, 0.72, 0.38, 0.10),
    (0.68, 0.84, 0.32, 0.08),
    (0.88, 0.62, 0.35, 0.09),
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
  bool shouldRepaint(covariant _DreamStarsPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _DreamSacredGeometryPainter extends CustomPainter {
  const _DreamSacredGeometryPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final r = size.shortestSide * 0.34;
    final tw = 0.5 + sin(phase * pi * 2) * 0.2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = AppColors.gold.withValues(alpha: 0.05 * tw);

    canvas.drawCircle(Offset(cx, cy), r, paint);
    canvas.drawCircle(Offset(cx, cy), r * 0.72, paint);

    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + phase * pi * 0.15;
      final p1 = Offset(cx + cos(angle) * r, cy + sin(angle) * r);
      final p2 = Offset(
        cx + cos(angle + pi / 3) * r,
        cy + sin(angle + pi / 3) * r,
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DreamSacredGeometryPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _DreamParticlesPainter extends CustomPainter {
  const _DreamParticlesPainter({required this.phase});

  final double phase;

  static const _dust = <(double x, double y)>[
    (0.08, 0.24),
    (0.18, 0.48),
    (0.32, 0.32),
    (0.44, 0.66),
    (0.58, 0.28),
    (0.72, 0.52),
    (0.84, 0.36),
    (0.92, 0.74),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _dust.length; i++) {
      final (x, y) = _dust[i];
      final drift = sin(phase * pi * 2 + i) * 3;
      final alpha = 0.10 + sin(phase * pi * 2 + i * 0.7) * 0.05;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        0.7,
        Paint()..color = AppColors.goldLight.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DreamParticlesPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

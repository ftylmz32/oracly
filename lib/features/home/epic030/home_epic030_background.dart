/// EPIC-030 — Approved Home background layers.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/design_system/app_gradients.dart';
import '../../../core/theme/app_colors.dart';

class HomeEpic030Background extends StatefulWidget {
  const HomeEpic030Background({super.key, required this.child});

  final Widget child;

  @override
  State<HomeEpic030Background> createState() => _HomeEpic030BackgroundState();
}

class _HomeEpic030BackgroundState extends State<HomeEpic030Background>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
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
        return Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.background),
              child: SizedBox.expand(),
            ),
            _NebulaBlob(
              top: 36 + sin(t * pi * 2) * 8,
              left: -64,
              size: 268,
              color: AppColors.purpleDark.withValues(alpha: 0.14),
            ),
            _NebulaBlob(
              top: 176,
              right: -84,
              size: 304,
              color: AppColors.purple.withValues(alpha: 0.10),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _StarFieldPainter(phase: t),
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _DustPainter(phase: t),
                size: Size.infinite,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.18),
                      radius: 1.22,
                      colors: [
                        AppColors.transparent,
                        Colors.black.withValues(alpha: 0.34),
                      ],
                      stops: const [0.52, 1.0],
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

class _NebulaBlob extends StatelessWidget {
  const _NebulaBlob({
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
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
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

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter({required this.phase});

  final double phase;

  static const _stars = <(double x, double y, double r, double a)>[
    (0.06, 0.10, 0.35, 0.10),
    (0.18, 0.06, 0.30, 0.08),
    (0.32, 0.14, 0.38, 0.11),
    (0.52, 0.08, 0.32, 0.09),
    (0.72, 0.12, 0.35, 0.10),
    (0.88, 0.06, 0.30, 0.08),
    (0.14, 0.38, 0.32, 0.09),
    (0.44, 0.52, 0.35, 0.08),
    (0.68, 0.68, 0.30, 0.07),
    (0.84, 0.82, 0.38, 0.10),
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
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _DustPainter extends CustomPainter {
  const _DustPainter({required this.phase});

  final double phase;

  static const _dust = <(double x, double y)>[
    (0.10, 0.22),
    (0.24, 0.44),
    (0.40, 0.30),
    (0.58, 0.58),
    (0.76, 0.36),
    (0.90, 0.64),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _dust.length; i++) {
      final (x, y) = _dust[i];
      final drift = sin(phase * pi * 2 + i) * 2.5;
      final alpha = 0.08 + sin(phase * pi * 2 + i * 0.7) * 0.04;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        0.65,
        Paint()..color = AppColors.goldLight.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

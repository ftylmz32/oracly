/// OR-1080 — Card detail mystical background with particles.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';

class CardDetailBackground extends StatefulWidget {
  const CardDetailBackground({super.key});

  @override
  State<CardDetailBackground> createState() => _CardDetailBackgroundState();
}

class _CardDetailBackgroundState extends State<CardDetailBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: OraclySignatureMaterials.ambientDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: OraclySignatureChamber.cosmic),
            CustomPaint(
              painter: _DetailParticles(phase: _drift.value * pi * 2),
              size: Size.infinite,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 1.2,
                    colors: [
                      AppColors.purpleGlow.withValues(alpha: 0.08),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailParticles extends CustomPainter {
  const _DetailParticles({required this.phase});

  final double phase;

  static const _pts = <(double x, double y, double r)>[
    (0.1, 0.18, 0.7),
    (0.28, 0.1, 0.5),
    (0.72, 0.12, 0.8),
    (0.9, 0.28, 0.6),
    (0.18, 0.42, 0.55),
    (0.58, 0.36, 0.65),
    (0.84, 0.52, 0.75),
    (0.36, 0.62, 0.5),
    (0.62, 0.72, 0.7),
    (0.14, 0.82, 0.55),
    (0.5, 0.88, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pts.length; i++) {
      final (x, y, r) = _pts[i];
      final tw = 0.55 + sin(phase + i * 0.65) * 0.35;
      final drift = sin(phase * 0.75 + i * 1.1) * 4;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        r,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.12 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DetailParticles oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

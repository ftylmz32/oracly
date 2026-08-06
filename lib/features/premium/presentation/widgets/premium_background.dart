/// OR-1090 — Premium screen mystical background.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/oracly_brand_signature.dart';

class PremiumBackground extends StatefulWidget {
  const PremiumBackground({super.key});

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
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
        final t = _drift.value * pi * 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: OraclySignatureChamber.cosmic),
            CustomPaint(
              painter: _GoldParticles(phase: t),
              size: Size.infinite,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.1,
                    colors: [
                      AppColors.goldGlow.withValues(alpha: 0.06),
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

class _GoldParticles extends CustomPainter {
  const _GoldParticles({required this.phase});

  final double phase;

  static const _pts = <(double x, double y, double r)>[
    (0.12, 0.15, 0.9),
    (0.35, 0.08, 0.6),
    (0.68, 0.12, 0.8),
    (0.88, 0.25, 0.5),
    (0.22, 0.38, 0.7),
    (0.55, 0.32, 0.65),
    (0.78, 0.48, 0.85),
    (0.15, 0.58, 0.55),
    (0.42, 0.68, 0.75),
    (0.72, 0.78, 0.6),
    (0.28, 0.88, 0.7),
    (0.62, 0.92, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pts.length; i++) {
      final (x, y, r) = _pts[i];
      final tw = 0.55 + sin(phase + i * 0.8) * 0.4;
      final drift = sin(phase * 0.7 + i) * 5;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        r,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.16 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldParticles oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

/// Stagger entrance for premium sections.
double premiumSectionEntrance(int index, double master) {
  final start = index * 0.06;
  final end = start + 0.26;
  if (master <= start) return 0;
  if (master >= end) return 1;
  return Curves.easeOutCubic.transform((master - start) / (end - start));
}

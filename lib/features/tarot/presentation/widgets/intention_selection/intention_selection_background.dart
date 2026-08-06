/// OR-404 — Atmospheric backdrop for the intention ritual.
library;

import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../components/tarot_particle_layer.dart';

class IntentionSelectionBackground extends StatefulWidget {
  const IntentionSelectionBackground({super.key});

  @override
  State<IntentionSelectionBackground> createState() =>
      _IntentionSelectionBackgroundState();
}

class _IntentionSelectionBackgroundState extends State<IntentionSelectionBackground>
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
        final t = _drift.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: OraclySignatureChamber.cosmic),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.55 + sin(t * pi * 2) * 0.02),
                    radius: 1.0,
                    colors: [
                      AppColors.purple.withValues(alpha: 0.16),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80 + sin(t * pi * 2 + 1) * 10,
              left: -40,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purpleDark.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _IntentionStars(phase: t),
              size: Size.infinite,
            ),
            const TarotParticleLayer(),
          ],
        );
      },
    );
  }
}

class _IntentionStars extends CustomPainter {
  const _IntentionStars({required this.phase});

  final double phase;

  static const _stars = <(double x, double y, double r, double a)>[
    (0.1, 0.14, 0.7, 0.28),
    (0.86, 0.1, 0.9, 0.32),
    (0.72, 0.32, 0.5, 0.22),
    (0.18, 0.48, 0.6, 0.24),
    (0.9, 0.58, 0.8, 0.26),
    (0.42, 0.72, 0.5, 0.20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final (x, y, r, a) = _stars[i];
      final twinkle = 0.65 + sin(phase * pi * 2 + i) * 0.35;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        Paint()..color = AppColors.goldLight.withValues(alpha: a * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IntentionStars old) => old.phase != phase;
}

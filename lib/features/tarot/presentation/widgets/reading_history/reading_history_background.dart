/// OR-1070 — Mystical journal background with floating particles.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/theme/oracly_quiet_motion.dart';

class ReadingHistoryBackground extends StatefulWidget {
  const ReadingHistoryBackground({super.key});

  @override
  State<ReadingHistoryBackground> createState() =>
      _ReadingHistoryBackgroundState();
}

class _ReadingHistoryBackgroundState extends State<ReadingHistoryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: OraclySignatureMaterials.ambientDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _drift, rest: 0.35);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    Widget layer(double t) => Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: OraclySignatureChamber.selection),
            RepaintBoundary(
              child: CustomPaint(
                painter: _JournalParticles(phase: t * pi * 2),
                size: Size.infinite,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [
                      Color(0x140C0828),
                      Color(0x00000000),
                      Color(0x6B000000),
                    ],
                    stops: [0.0, 0.52, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );

    return still
        ? layer(0.35)
        : AnimatedBuilder(
            animation: _drift,
            builder: (context, _) => layer(_drift.value),
          );
  }
}

class _JournalParticles extends CustomPainter {
  const _JournalParticles({required this.phase});

  final double phase;

  static const _pts = <(double x, double y, double r)>[
    (0.08, 0.12, 0.8),
    (0.22, 0.08, 0.6),
    (0.78, 0.14, 0.9),
    (0.92, 0.22, 0.5),
    (0.15, 0.34, 0.7),
    (0.55, 0.28, 0.6),
    (0.88, 0.42, 0.8),
    (0.32, 0.52, 0.5),
    (0.68, 0.58, 0.7),
    (0.12, 0.72, 0.6),
    (0.48, 0.78, 0.9),
    (0.82, 0.86, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pts.length; i++) {
      final (x, y, r) = _pts[i];
      final tw = 0.6 + sin(phase + i * 0.7) * 0.35;
      final drift = sin(phase * 0.8 + i) * 3;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        r,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.14 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JournalParticles oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

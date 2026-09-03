/// OR-1050+ — Magical particle burst emitted during card flip.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class RevealFlipParticles extends StatelessWidget {
  const RevealFlipParticles({
    super.key,
    required this.intensity,
    required this.flipAngle,
    this.width = 168,
    this.height = 268,
  });

  final double intensity;
  final double flipAngle;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0.02) return const SizedBox.shrink();

    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(width + 80, height + 80),
          painter: _FlipBurstPainter(
            intensity: intensity,
            flipAngle: flipAngle,
          ),
        ),
      ),
    );
  }
}

class _FlipBurstPainter extends CustomPainter {
  _FlipBurstPainter({required this.intensity, required this.flipAngle});

  final double intensity;
  final double flipAngle;

  static const _count = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final spread = intensity * 48;

    for (var i = 0; i < _count; i++) {
      final angle = (i / _count) * math.pi * 2 + flipAngle * 0.4;
      final dist = spread * (0.4 + (i % 5) * 0.12);
      final alpha = intensity * (0.35 + (i % 3) * 0.15);
      final color = switch (i % 3) {
        0 => AppColors.goldLight,
        1 => AppColors.purpleLight,
        _ => AppColors.white,
      };
      final r = 1.0 + (i % 4) * 0.4;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist * 0.65),
        r,
        Paint()..color = color.withValues(alpha: alpha.clamp(0.0, 0.85)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlipBurstPainter old) =>
      old.intensity != intensity || old.flipAngle != flipAngle;
}

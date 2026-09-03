/// OR-1050 — Animated gold energy trace around revealed card.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class RevealBorderEnergy extends StatelessWidget {
  const RevealBorderEnergy({
    super.key,
    required this.progress,
    required this.width,
    required this.height,
  });

  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.01) return const SizedBox.shrink();

    return CustomPaint(
      size: Size(width + 24, height + 24),
      painter: _BorderEnergyPainter(progress: progress),
    );
  }
}

class _BorderEnergyPainter extends CustomPainter {
  const _BorderEnergyPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(10),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().first;
    final sweep = metrics.length * progress * 0.72;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..shader = LinearGradient(
        colors: [
          AppColors.goldLight.withValues(alpha: 0.28 * progress),
          AppColors.gold.withValues(alpha: 0.16 * progress),
          AppColors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(metrics.extractPath(0, sweep), paint);
  }

  @override
  bool shouldRepaint(covariant _BorderEnergyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

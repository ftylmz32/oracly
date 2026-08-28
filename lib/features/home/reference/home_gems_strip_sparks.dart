/// Subtle facet sparks for the home gems strip plate.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeGemsStripSparksPainter extends CustomPainter {
  const HomeGemsStripSparksPainter({
    required this.phase,
    required this.intensity,
  });

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final spots = <Offset>[
      Offset(size.width * 0.42, size.height * 0.32),
      Offset(size.width * 0.68, size.height * 0.48),
      Offset(size.width * 0.54, size.height * 0.62),
      Offset(size.width * 0.78, size.height * 0.28),
    ];
    for (var i = 0; i < spots.length; i++) {
      final pulse = 0.55 + math.sin((phase + i * 0.17) * math.pi * 2) * 0.45;
      final r = 1.1 + (i.isEven ? 0.4 : 0.0);
      final paint = Paint()
        ..color = AppColors.goldLight.withValues(
          alpha: (0.10 + intensity * 0.55) * pulse,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
      canvas.drawCircle(spots[i], r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HomeGemsStripSparksPainter old) =>
      old.phase != phase || old.intensity != intensity;
}

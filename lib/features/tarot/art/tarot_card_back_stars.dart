/// Sparse cosmic dust for the Oracly deck back — never UI chrome.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TarotCardBackStars extends StatelessWidget {
  const TarotCardBackStars({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _StarsPainter(), child: SizedBox.expand()),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold.withValues(alpha: 0.22);
    for (var i = 0; i < 14; i++) {
      final a = i * 2.399963;
      final r = size.shortestSide * (0.18 + (i % 5) * 0.07);
      final c = Offset(size.width * 0.5, size.height * 0.5);
      final p = c + Offset(math.cos(a) * 0.95, math.sin(a) * 1.15) * r;
      canvas.drawCircle(p, 0.55 + (i % 3) * 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

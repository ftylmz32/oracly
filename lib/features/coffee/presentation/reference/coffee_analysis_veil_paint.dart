/// Soft dust + quiet progress for coffee analysis veil.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class CoffeeAnalysisQuietProgress extends StatelessWidget {
  const CoffeeAnalysisQuietProgress({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: OraclyChrome.gold.withValues(alpha: 0.14)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.08, 1.0),
              child: ColoredBox(
                color: OraclyChrome.goldLight.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoffeeAnalysisDustPainter extends CustomPainter {
  const CoffeeAnalysisDustPainter({required this.phase});

  final double phase;

  static const _pts = <(double x, double y, double r, double speed)>[
    (-0.28, -0.18, 0.9, 0.7),
    (-0.08, 0.12, 0.75, 1.0),
    (0.18, -0.22, 0.85, 0.85),
    (0.32, 0.08, 0.7, 1.1),
    (-0.22, 0.22, 0.8, 0.9),
    (0.06, -0.06, 0.65, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    for (var i = 0; i < _pts.length; i++) {
      final (nx, ny, r, speed) = _pts[i];
      final drift = math.sin(phase * speed + i) * 5;
      final lift = math.cos(phase * speed * 0.8 + i) * 4;
      final tw = 0.45 + math.sin(phase * 1.2 + i) * 0.3;
      canvas.drawCircle(
        Offset(
          cx + nx * size.width * 0.42 + drift,
          cy + ny * size.height * 0.36 + lift,
        ),
        r,
        Paint()..color = OraclyChrome.goldLight.withValues(alpha: 0.10 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CoffeeAnalysisDustPainter old) =>
      old.phase != phase;
}

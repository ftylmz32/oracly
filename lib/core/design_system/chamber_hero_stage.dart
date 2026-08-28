/// Circular gold geometry around a ritual hero — cup, palm, or sky.
library;

import 'package:flutter/material.dart';

import 'oracly_chrome.dart';

class ChamberHeroStage extends StatelessWidget {
  const ChamberHeroStage({
    super.key,
    required this.child,
    this.warm = false,
    this.glow = 1,
  });

  final Widget child;
  final bool warm;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final gold = (warm ? 0.22 : 0.16) * glow;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    (warm ? const Color(0xFF5A3A18) : OraclyChrome.violet)
                        .withValues(alpha: 0.28 * glow),
                    OraclyChrome.gold.withValues(alpha: gold * 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GoldRingsPainter()),
          ),
        ),
        child,
      ],
    );
  }
}

class _GoldRingsPainter extends CustomPainter {
  const _GoldRingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.48);
    final r = size.shortestSide * 0.42;
    for (final scale in [1.0, 0.78, 0.56]) {
      canvas.drawCircle(
        c,
        r * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale == 1 ? 1.05 : 0.7
          ..color = OraclyChrome.gold.withValues(
            alpha: scale == 1 ? 0.42 : 0.18,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

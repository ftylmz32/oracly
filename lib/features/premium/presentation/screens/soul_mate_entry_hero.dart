/// Cinematic entry atmosphere — violet, gold, silhouettes, restrained glow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class SoulMateEntryHero extends StatelessWidget {
  const SoulMateEntryHero({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 21 / 9,
      child: ClipRRect(
        borderRadius: OraclyChrome.heroRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0614),
                    OraclyChrome.violet.withValues(alpha: 0.95),
                    const Color(0xFF120A22),
                  ],
                ),
              ),
            ),
            const CustomPaint(painter: _SoulMateHeroPainter()),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoulMateHeroPainter extends CustomPainter {
  const _SoulMateHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(17);
    for (var i = 0; i < 28; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.72;
      final r = rnd.nextDouble() * 1.4 + 0.3;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.08 + rnd.nextDouble() * 0.18),
      );
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          OraclyChrome.gold.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.72),
        radius: size.width * 0.38,
      ));
    canvas.drawRect(Offset.zero & size, glow);

    final silhouette = Paint()..color = const Color(0xE6100818);
    final cx = size.width * 0.5;
    final base = size.height * 0.78;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.12, base - size.height * 0.22),
        width: size.width * 0.14,
        height: size.height * 0.16,
      ),
      silhouette,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.12, base - size.height * 0.24),
        width: size.width * 0.13,
        height: size.height * 0.15,
      ),
      silhouette,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - size.width * 0.12, base),
          width: size.width * 0.18,
          height: size.height * 0.28,
        ),
        const Radius.circular(28),
      ),
      silhouette,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + size.width * 0.12, base + 4),
          width: size.width * 0.17,
          height: size.height * 0.27,
        ),
        const Radius.circular(28),
      ),
      silhouette,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

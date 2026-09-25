/// Static painter/layers for [TarotTableBackground] (Phase 7B).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../theme/tarot_tokens.dart';

class TarotTableNavyWash extends StatelessWidget {
  const TarotTableNavyWash({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.15),
          radius: 1.15,
          colors: [
            TarotTokens.tableNavyMid.withValues(alpha: 0.95),
            TarotTokens.tableNavyDeep,
            TarotTokens.tableVoid,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class TarotTableCelestialRing extends StatelessWidget {
  const TarotTableCelestialRing({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: TarotTableCelestialPainter());
  }
}

class TarotTableCelestialPainter extends CustomPainter {
  const TarotTableCelestialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.52);
    final r = size.shortestSide * 0.38;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.gold.withValues(alpha: 0.14);
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(
      c,
      r * 0.72,
      paint..color = AppColors.gold.withValues(alpha: 0.08),
    );
    final tick = Paint()
      ..strokeWidth = 0.7
      ..color = AppColors.gold.withValues(alpha: 0.12);
    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2;
      final p0 = c + Offset(math.cos(a), math.sin(a)) * (r * 0.92);
      final p1 = c + Offset(math.cos(a), math.sin(a)) * (r * 1.02);
      canvas.drawLine(p0, p1, tick);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TarotTableCandleSpill extends StatelessWidget {
  const TarotTableCandleSpill({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(-0.85, 0.1),
      child: IgnorePointer(
        child: Container(
          width: 160,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                TarotTokens.tableCandleWarm.withValues(alpha: 0.10),
                TarotTokens.tableCandleDeep.withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TarotTableVioletBloom extends StatelessWidget {
  const TarotTableVioletBloom({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0.9, -0.2),
      child: IgnorePointer(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                TarotTokens.tableVioletBloom.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TarotTableVignette extends StatelessWidget {
  const TarotTableVignette({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.05,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
          ],
          stops: const [0.55, 1.0],
        ),
      ),
    );
  }
}

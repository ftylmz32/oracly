/// Premium printed-card material — fiber, matte, foil, grain. Never a neon glow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';

export 'tarot_contact_shadow.dart';

/// Soft overlays that make a card read as paper + antique gold print.
class TarotPrintedMaterial extends StatelessWidget {
  const TarotPrintedMaterial({
    super.key,
    this.lightBiasX = 0,
    this.lightBiasY = 0,
    this.foil = 0.55,
    this.matte = 0.55,
  });

  final double lightBiasX;
  final double lightBiasY;
  final double foil;
  final double matte;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft matte paper — kills plastic shine.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.2 + lightBiasX * 0.2, -0.35 + lightBiasY * 0.15),
                radius: 1.15,
                colors: [
                  Colors.white.withValues(alpha: 0.03 * matte),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.10 * matte),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          CustomPaint(
            painter: _PaperFiberPainter(
              biasX: lightBiasX,
              biasY: lightBiasY,
            ),
          ),
          // Antique gold foil catch — responds to rotation bias.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  -0.9 + lightBiasX * 0.55,
                  -1.0 + lightBiasY * 0.35,
                ),
                end: Alignment(
                  0.35 + lightBiasX * 0.25,
                  0.55 + lightBiasY * 0.2,
                ),
                colors: [
                  OraclySignaturePalette.champagne.withValues(
                    alpha: 0.09 * foil + lightBiasX.abs() * 0.04,
                  ),
                  Colors.transparent,
                  OraclySignaturePalette.champagneDeep.withValues(
                    alpha: 0.065 * foil,
                  ),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperFiberPainter extends CustomPainter {
  _PaperFiberPainter({required this.biasX, required this.biasY});

  final double biasX;
  final double biasY;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(41);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = 0.012 + rnd.nextDouble() * 0.028;
      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x + biasX * 1.5, y + biasY * 1.2), 0.35 + rnd.nextDouble() * 0.55, paint);
    }
    for (var i = 0; i < 22; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      paint.color = Colors.black.withValues(alpha: 0.018 + rnd.nextDouble() * 0.02);
      canvas.drawCircle(Offset(x, y), 0.4 + rnd.nextDouble() * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperFiberPainter oldDelegate) =>
      oldDelegate.biasX != biasX || oldDelegate.biasY != biasY;
}

/// Luxurious table bed — velvet nap, candle wash, gold rim reflection.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';

/// Soft oval cloth under a resting or fanned deck. Ignore-pointer only.
class TarotDeckTableAtmosphere extends StatelessWidget {
  const TarotDeckTableAtmosphere({
    super.key,
    this.width = 280,
    this.height = 110,
    this.intensity = 1,
    this.candleBias = const Alignment(-0.35, -0.55),
  });

  final double width;
  final double height;
  final double intensity;
  final Alignment candleBias;

  @override
  Widget build(BuildContext context) {
    final a = intensity.clamp(0.0, 1.0);
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Deep contact shadow into the table.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 16),
              child: Container(
                width: width * 0.92,
                height: height * 0.72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Colors.black.withValues(alpha: 0.48 * a),
                ),
              ),
            ),
            // Velvet body — plum-obsidian nap.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 11),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(90),
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.12),
                    radius: 0.98,
                    colors: [
                      const Color(0xFF3A142E).withValues(alpha: 0.62 * a),
                      const Color(0xFF1A0A16).withValues(alpha: 0.78 * a),
                      OraclySignaturePalette.obsidian.withValues(alpha: 0.55 * a),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.38, 0.72, 1.0],
                  ),
                ),
              ),
            ),
            // Candlelight spill — warm, low, from one side.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 22),
              child: Align(
                alignment: candleBias,
                child: Container(
                  width: width * 0.55,
                  height: height * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE8C872).withValues(alpha: 0.14 * a),
                        const Color(0xFFC48A3A).withValues(alpha: 0.07 * a),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Gold rim reflection — hairline catch on the cloth.
            CustomPaint(
              size: Size(width, height),
              painter: _GoldRimPainter(alpha: 0.22 * a),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldRimPainter extends CustomPainter {
  const _GoldRimPainter({required this.alpha});

  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0.01) return;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.48),
      width: size.width * 0.86,
      height: size.height * 0.58,
    );
    final path = Path()..addOval(rect);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclySignaturePalette.champagne.withValues(alpha: alpha),
            Colors.transparent,
            OraclySignaturePalette.champagneDeep.withValues(alpha: alpha * 0.55),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GoldRimPainter old) => old.alpha != alpha;
}

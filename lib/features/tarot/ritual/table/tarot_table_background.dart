/// Full-screen mystical table environment — continuous across phases.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TarotTableBackground extends StatelessWidget {
  const TarotTableBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Color(0xFF05030A)),
        _NavyWash(),
        _CelestialRing(),
        _WarmCandleSpill(),
        _VioletBloom(),
        _SoftVignette(),
      ],
    );
  }
}

class _NavyWash extends StatelessWidget {
  const _NavyWash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.15),
          radius: 1.15,
          colors: [
            const Color(0xFF1A1230).withValues(alpha: 0.95),
            const Color(0xFF0B0716),
            const Color(0xFF05030A),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class _CelestialRing extends StatelessWidget {
  const _CelestialRing();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CelestialPainter());
  }
}

class _CelestialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.52);
    final r = size.shortestSide * 0.38;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.gold.withValues(alpha: 0.14);
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c, r * 0.72, paint..color = AppColors.gold.withValues(alpha: 0.08));
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

class _WarmCandleSpill extends StatelessWidget {
  const _WarmCandleSpill();

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
                const Color(0xFFE8C872).withValues(alpha: 0.10),
                const Color(0xFFC48A3A).withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VioletBloom extends StatelessWidget {
  const _VioletBloom();

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
                const Color(0xFF6B3FA0).withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftVignette extends StatelessWidget {
  const _SoftVignette();

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

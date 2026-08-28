/// Soft gold emblem glow + tiny star shimmer over the same final art.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashFinalLights extends StatelessWidget {
  const SplashFinalLights({
    super.key,
    required this.emblemGlow,
    required this.starShimmer,
    required this.goldPass,
    this.reduced = false,
  });

  final double emblemGlow;
  final double starShimmer;
  final double goldPass;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    if (reduced) {
      return IgnorePointer(
        child: CustomPaint(
          painter: _EmblemGlowPainter(emblemGlow * 0.55),
          child: const SizedBox.expand(),
        ),
      );
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _LightsPainter(
          emblemGlow: emblemGlow,
          starShimmer: starShimmer,
          goldPass: goldPass,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EmblemGlowPainter extends CustomPainter {
  _EmblemGlowPainter(this.strength);
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0.01) return;
    final center = Offset(size.width * 0.5, size.height * 0.36);
    final radius = size.shortestSide * 0.28;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD4AF77).withValues(alpha: 0.22 * strength),
          const Color(0xFFD4AF77).withValues(alpha: 0.06 * strength),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _EmblemGlowPainter old) =>
      old.strength != strength;
}

class _LightsPainter extends CustomPainter {
  _LightsPainter({
    required this.emblemGlow,
    required this.starShimmer,
    required this.goldPass,
  });

  final double emblemGlow;
  final double starShimmer;
  final double goldPass;

  @override
  void paint(Canvas canvas, Size size) {
    _paintEmblem(canvas, size);
    if (starShimmer > 0.02) _paintStars(canvas, size);
    if (goldPass > 0.02 && goldPass < 0.98) _paintPass(canvas, size);
  }

  void _paintEmblem(Canvas canvas, Size size) {
    if (emblemGlow <= 0.01) return;
    final center = Offset(size.width * 0.5, size.height * 0.36);
    final radius = size.shortestSide * 0.30;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8C98A).withValues(alpha: 0.26 * emblemGlow),
          const Color(0xFFD4AF77).withValues(alpha: 0.10 * emblemGlow),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _paintStars(Canvas canvas, Size size) {
    const anchors = <Offset>[
      Offset(0.50, 0.12),
      Offset(0.72, 0.22),
      Offset(0.28, 0.24),
      Offset(0.58, 0.78),
      Offset(0.40, 0.70),
    ];
    for (var i = 0; i < anchors.length; i++) {
      final p = Offset(size.width * anchors[i].dx, size.height * anchors[i].dy);
      final pulse = 0.35 +
          0.65 *
              (0.5 +
                  0.5 *
                      math.sin((starShimmer * math.pi * 2) + i * 1.3));
      final alpha = 0.18 * starShimmer * pulse;
      final paint = Paint()
        ..color = const Color(0xFFE8C98A).withValues(alpha: alpha);
      canvas.drawCircle(p, 1.2 + (i % 2) * 0.6, paint);
    }
  }

  void _paintPass(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.36);
    final radius = size.shortestSide * 0.34;
    final sweep = goldPass;
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.35 + sweep * 0.7, -0.15),
        radius: 0.55,
        colors: [
          Colors.transparent,
          const Color(0xFFE8C98A).withValues(alpha: 0.14),
          Colors.transparent,
        ],
        stops: const [0.25, 0.5, 0.78],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _LightsPainter old) =>
      old.emblemGlow != emblemGlow ||
      old.starShimmer != starShimmer ||
      old.goldPass != goldPass;
}

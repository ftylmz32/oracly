/// OR-301+ — Subtle per-card particle ambience (GPU-friendly CustomPaint).
library;

import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';

import 'reading_section_theme.dart';

class ReadingCardAmbience extends StatelessWidget {
  const ReadingCardAmbience({
    super.key,
    required this.theme,
    required this.phase,
  });

  final ReadingSectionTheme theme;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AmbiencePainter(
          kind: theme.particleKind,
          glowColor: theme.glowColor,
          phase: phase,
          metallic: theme.metallicSheen,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AmbiencePainter extends CustomPainter {
  _AmbiencePainter({
    required this.kind,
    required this.glowColor,
    required this.phase,
    required this.metallic,
  });

  final ReadingParticleKind kind;
  final Color glowColor;
  final double phase;
  final bool metallic;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = glowColor.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.35,
      glow,
    );

    if (metallic) {
      final sheen = Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + phase * 0.4, -0.5),
          end: Alignment(0.5 + phase * 0.4, 1),
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16),
        ),
        sheen,
      );
    }

    switch (kind) {
      case ReadingParticleKind.hearts:
        _drawHearts(canvas, size);
      case ReadingParticleKind.sparkles:
      case ReadingParticleKind.stars:
        _drawStars(canvas, size, kind == ReadingParticleKind.stars);
      case ReadingParticleKind.dust:
        _drawDust(canvas, size);
    }
  }

  void _drawHearts(Canvas canvas, Size size) {
    const spots = [(0.82, 0.22), (0.12, 0.72), (0.68, 0.78)];
    for (var i = 0; i < spots.length; i++) {
      final (x, y) = spots[i];
      final drift = sin(phase + i) * 3;
      final alpha = 0.12 + sin(phase * 1.2 + i) * 0.08;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        2.5,
        Paint()..color = const Color(0xFFFF8FB8).withValues(alpha: alpha),
      );
    }
  }

  void _drawStars(Canvas canvas, Size size, bool animated) {
    const spots = [(0.15, 0.18), (0.88, 0.28), (0.72, 0.65), (0.25, 0.82)];
    for (var i = 0; i < spots.length; i++) {
      final (x, y) = spots[i];
      final tw = animated
          ? 0.25 + sin(phase * 2 + i * 1.1) * 0.2
          : 0.2 + sin(phase + i) * 0.1;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y + sin(phase + i) * 2),
        1.2 + i * 0.2,
        Paint()..color = glowColor.withValues(alpha: tw),
      );
    }
  }

  void _drawDust(Canvas canvas, Size size) {
    for (var i = 0; i < 6; i++) {
      final x = 0.1 + (i * 0.15) % 0.8;
      final y = 0.15 + (i * 0.17) % 0.7;
      canvas.drawCircle(
        Offset(
          size.width * x + cos(phase + i) * 2,
          size.height * y + sin(phase * 0.8 + i) * 2,
        ),
        0.8,
        Paint()
          ..color = glowColor.withValues(alpha: 0.08 + sin(phase + i) * 0.04),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbiencePainter old) =>
      old.phase != phase || old.kind != kind;
}

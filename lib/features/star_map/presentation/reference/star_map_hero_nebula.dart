/// Soft candle–violet halo behind the archive plate. Never natal, never a wheel.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'star_map_reference_tokens.dart';

class StarMapHeroNebula extends StatelessWidget {
  const StarMapHeroNebula({super.key, required this.size, this.phase = 0});

  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _NebulaPainter(phase: phase),
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  const _NebulaPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.48;
    // Quiet breath — felt as warmth, not a pulse.
    final pulse = 0.92 + math.sin(phase * math.pi * 2) * 0.03;
    canvas.drawCircle(
      c,
      r * 1.06,
      Paint()
        ..color = StarMapReferenceTokens.candleAmber
            .withValues(alpha: 0.16 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    canvas.drawCircle(
      c,
      r * 0.88,
      Paint()
        ..color = StarMapReferenceTokens.violetSky
            .withValues(alpha: 0.36 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
      c,
      r * 0.58,
      Paint()
        ..color = StarMapReferenceTokens.archiveInk
            .withValues(alpha: 0.20 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    final fleck = Paint();
    for (var i = 0; i < 6; i++) {
      final a = (i / 6) * math.pi * 2 + phase * 0.22;
      final dist = r * (0.90 + (i % 2) * 0.03);
      fleck.color = StarMapReferenceTokens.brassGlow.withValues(
        alpha: 0.07 + (i % 3) * 0.025,
      );
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * dist, c.dy + math.sin(a) * dist),
        i.isEven ? 0.75 : 0.45,
        fleck,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter old) => old.phase != phase;
}

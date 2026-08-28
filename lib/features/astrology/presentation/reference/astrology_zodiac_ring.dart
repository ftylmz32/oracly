/// Tropical zodiac instrument ring — metallic depth; only real bodies.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'astrology_planet_glyphs.dart';
import 'astrology_sign_glyphs.dart';
import 'astrology_supported_bodies_paint.dart';
import 'astrology_supported_sky.dart';
import 'astrology_zodiac_ring_polish.dart';

class AstrologyZodiacRingPainter extends CustomPainter {
  const AstrologyZodiacRingPainter({
    required this.sky,
    this.phase = 0.4,
  });

  final AstrologySupportedSky sky;
  final double phase;

  static const signs = <String>[
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.46;
    AstrologyZodiacRingPolish.depthOrbits(canvas, c, r);
    AstrologyZodiacRingPolish.particles(canvas, c, r, phase);

    final selected = signs.indexOf(sky.sunSignId).clamp(0, 11);
    for (var i = 0; i < 12; i++) {
      final a = -math.pi / 2 + (i - selected) * math.pi / 6;
      final dir = Offset(math.cos(a), math.sin(a));
      final onRing = c + dir * (r * 0.90);
      final isSelected = i == selected;
      if (isSelected) {
        AstrologyZodiacRingPolish.selectedGlow(canvas, c, r, a, phase);
      }
      canvas.drawLine(
        c + dir * (r * 0.952),
        c + dir * r,
        Paint()
          ..color = OraclyChrome.goldLight
              .withValues(alpha: isSelected ? 0.92 : 0.38)
          ..strokeWidth = isSelected ? 1.55 : 0.85
          ..strokeCap = StrokeCap.round,
      );
      AstrologyZodiacRingPolish.metallicNode(canvas, onRing, isSelected);
      _glyph(
        canvas,
        signs[i],
        onRing,
        r * (isSelected ? 0.086 : 0.062),
        alpha: isSelected ? 0.98 : 0.48,
      );
      if (isSelected) {
        AstrologyPlanetGlyphs.paintSun(
          canvas,
          c + dir * (r * 0.72),
          r * 0.055,
          alpha: 0.88,
        );
      }
    }
    AstrologySupportedBodiesPaint.paint(canvas, c, r, selected, sky);
    _apexSpark(canvas, Offset(c.dx, c.dy - r), phase);
  }

  void _apexSpark(Canvas canvas, Offset p, double phase) {
    final breath = 0.7 + math.sin(phase * math.pi * 2) * 0.2;
    canvas.drawCircle(
      p,
      2.4,
      Paint()
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.22 * breath)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawCircle(
      p,
      1.35,
      Paint()..color = OraclyChrome.goldLight.withValues(alpha: 0.94),
    );
  }

  void _glyph(
    Canvas canvas,
    String id,
    Offset pos,
    double visualR, {
    required double alpha,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(visualR / 22.0);
    AstrologySignGlyphs.paint(canvas, id, Offset.zero, 22, alpha: alpha);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AstrologyZodiacRingPainter old) =>
      old.sky.sunSignId != sky.sunSignId ||
      old.sky.moonSignId != sky.moonSignId ||
      old.sky.planetSignIds != sky.planetSignIds ||
      old.phase != phase;
}

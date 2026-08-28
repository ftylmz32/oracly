/// Paints optional Moon/planet marks — only when [AstrologySupportedSky] has them.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'astrology_planet_glyphs.dart';
import 'astrology_supported_sky.dart';
import 'astrology_zodiac_ring.dart';

abstract final class AstrologySupportedBodiesPaint {
  AstrologySupportedBodiesPaint._();

  static void paint(
    Canvas canvas,
    Offset c,
    double r,
    int sunIndex,
    AstrologySupportedSky sky,
  ) {
    final moon = sky.moonSignId;
    if (moon != null && moon.isNotEmpty) {
      final i = AstrologyZodiacRingPainter.signs.indexOf(moon);
      if (i >= 0) {
        final a = -math.pi / 2 + (i - sunIndex) * math.pi / 6;
        final dir = Offset(math.cos(a), math.sin(a));
        AstrologyPlanetGlyphs.paintMoon(
          canvas,
          c + dir * (r * 0.58),
          r * 0.048,
        );
      }
    }
    for (final entry in sky.planetSignIds.entries) {
      final i = AstrologyZodiacRingPainter.signs.indexOf(entry.value);
      if (i < 0) continue;
      final a = -math.pi / 2 + (i - sunIndex) * math.pi / 6;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawCircle(
        c + dir * (r * 0.5),
        r * 0.018,
        Paint()..color = OraclyChrome.goldLight.withValues(alpha: 0.7),
      );
    }
  }
}

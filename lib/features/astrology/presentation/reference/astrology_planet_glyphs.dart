/// Planet line glyphs — only for bodies with real supported identity.
///
/// Hub default: tropical Sun only. Moon/planets paint only when provided.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

abstract final class AstrologyPlanetGlyphs {
  AstrologyPlanetGlyphs._();

  static void paintSun(
    Canvas canvas,
    Offset c,
    double r, {
    double alpha = 0.9,
  }) {
    final stroke = Paint()
      ..color = OraclyChrome.goldLight.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * 0.12)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r * 0.42, stroke);
    canvas.drawCircle(
      c,
      r * 0.14,
      Paint()..color = OraclyChrome.goldLight.withValues(alpha: alpha * 0.85),
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final inner = c + Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55);
      final outer = c + Offset(math.cos(a) * r * 0.92, math.sin(a) * r * 0.92);
      canvas.drawLine(
        inner,
        outer,
        stroke..strokeWidth = math.max(1.0, r * 0.1),
      );
    }
  }

  /// Crescent — only when a real Moon placement exists.
  static void paintMoon(
    Canvas canvas,
    Offset c,
    double r, {
    double alpha = 0.88,
  }) {
    final fill = Paint()
      ..color = OraclyChrome.cream.withValues(alpha: alpha * 0.9);
    canvas.drawCircle(c, r * 0.55, fill);
    canvas.drawCircle(
      c + Offset(r * 0.22, -r * 0.08),
      r * 0.48,
      Paint()..color = OraclyChrome.midnight.withValues(alpha: 0.92),
    );
  }
}

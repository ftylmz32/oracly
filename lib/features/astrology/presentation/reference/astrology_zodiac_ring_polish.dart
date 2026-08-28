/// Quiet depth, metallic gold, and celestial particles for the zodiac ring.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

abstract final class AstrologyZodiacRingPolish {
  AstrologyZodiacRingPolish._();

  static void depthOrbits(Canvas canvas, Offset c, double r) {
    // Recessed metal under-stroke.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = OraclyChrome.midnight.withValues(alpha: 0.62),
    );
    // Outer metallic gold.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.72)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..color = OraclyChrome.gold.withValues(alpha: 0.88),
    );
    // Inner rings — quieter depth.
    canvas.drawCircle(
      c,
      r * 0.835,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.32),
    );
    canvas.drawCircle(
      c,
      r * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.14),
    );
  }

  static void selectedGlow(
    Canvas canvas,
    Offset c,
    double r,
    double angle,
    double phase,
  ) {
    final breath = 0.55 + math.sin(phase * math.pi * 2) * 0.12;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final focus = c + dir * (r * 0.90);
    canvas.drawCircle(
      focus,
      r * 0.11,
      Paint()
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.16 * breath)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      focus,
      r * 0.055,
      Paint()
        ..color = OraclyChrome.gold.withValues(alpha: 0.10 * breath)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  static void particles(
    Canvas canvas,
    Offset c,
    double r,
    double phase,
  ) {
    final rnd = math.Random(41);
    for (var i = 0; i < 18; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final d = r * (0.74 + rnd.nextDouble() * 0.20);
      final p = c + Offset(math.cos(a) * d, math.sin(a) * d);
      final twinkle =
          0.35 + 0.65 * ((math.sin((phase + i * 0.13) * math.pi * 2) + 1) / 2);
      final size = 0.45 + rnd.nextDouble() * 0.85;
      canvas.drawCircle(
        p,
        size,
        Paint()
          ..color = OraclyChrome.cream.withValues(alpha: 0.10 + 0.28 * twinkle),
      );
      if (i.isEven) {
        canvas.drawCircle(
          p,
          size * 2.2,
          Paint()
            ..color = OraclyChrome.goldLight.withValues(alpha: 0.04 + 0.08 * twinkle)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
        );
      }
    }
  }

  static void metallicNode(Canvas canvas, Offset p, bool selected) {
    if (selected) {
      canvas.drawCircle(
        p,
        6.4,
        Paint()
          ..color = OraclyChrome.goldLight.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawCircle(
      p,
      selected ? 2.35 : 1.25,
      Paint()..color = OraclyChrome.midnight.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      p,
      selected ? 2.05 : 1.15,
      Paint()
        ..color =
            OraclyChrome.goldLight.withValues(alpha: selected ? 0.96 : 0.58),
    );
    if (selected) {
      canvas.drawCircle(
        p + const Offset(-0.5, -0.6),
        0.55,
        Paint()..color = OraclyChrome.cream.withValues(alpha: 0.55),
      );
    }
  }
}

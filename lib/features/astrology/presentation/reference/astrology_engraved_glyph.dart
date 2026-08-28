/// Center glyph as brass engraving — physically seated in the instrument.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'astrology_sign_glyphs.dart';

abstract final class AstrologyEngravedGlyph {
  AstrologyEngravedGlyph._();

  static void paint(
    Canvas canvas,
    String id,
    Offset c,
    double r,
  ) {
    // Recessed metal well.
    canvas.drawCircle(
      c,
      r * 1.12,
      Paint()
        ..color = OraclyChrome.midnight.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      c,
      r * 1.02,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = OraclyChrome.gold.withValues(alpha: 0.34),
    );
    // Deep carved under-stroke.
    canvas.save();
    canvas.translate(0.7, 0.9);
    AstrologySignGlyphs.paint(
      canvas,
      id,
      c,
      r,
      alpha: 0.55,
      color: OraclyChrome.midnight,
    );
    canvas.restore();
    // Aged brass face.
    AstrologySignGlyphs.paint(
      canvas,
      id,
      c,
      r,
      alpha: 0.96,
      color: OraclyChrome.goldLight,
    );
    // Soft highlight catch on the metal.
    canvas.drawCircle(
      c + Offset(-r * 0.22, -r * 0.28),
      r * 0.18,
      Paint()
        ..color = OraclyChrome.cream.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );
  }
}

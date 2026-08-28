/// Story 9:16 campaign layout — protect face, card, cup, main subject.
library;

import 'package:flutter/painting.dart';

abstract final class DiscoveryShareCardLayout {
  DiscoveryShareCardLayout._();

  /// Primary Story format.
  static const width = 1080.0;
  static const height = 1920.0;

  static const margin = 64.0;
  static const frameInset = 52.0;

  static Rect get frame => Rect.fromLTWH(
        frameInset,
        frameInset,
        width - frameInset * 2,
        height - frameInset * 2,
      );

  /// Hero plate — upper-mid, leaves room for gold type above and insight below.
  static Rect get hero => const Rect.fromLTWH(150, 420, 780, 980);

  /// Portrait / face-safe plate — slightly taller bias upward.
  static Rect get portrait => const Rect.fromLTWH(210, 400, 660, 900);

  /// Tarot card plate — tall contain zone.
  static Rect get card => const Rect.fromLTWH(270, 400, 540, 900);

  /// Cup plate — elegant editorial crop window.
  static Rect get cup => const Rect.fromLTWH(180, 440, 720, 860);

  static const brandY = 118.0;
  static const featureY = 178.0;
  static const subjectY = 248.0;
  static const insightY = 1480.0;
  static const footerY = 1788.0;

  /// Cover crop biased toward subject (0 = top, 1 = bottom).
  static Rect protectedCover(
    Rect src,
    Rect dest, {
    double focusY = 0.38,
  }) {
    final scale = dest.width / src.width > dest.height / src.height
        ? dest.width / src.width
        : dest.height / src.height;
    final w = dest.width / scale;
    final h = dest.height / scale;
    final left = src.left + (src.width - w) / 2;
    final top = src.top + (src.height - h) * focusY.clamp(0.18, 0.55);
    return Rect.fromLTWH(left, top, w, h);
  }

  /// Contain — never crop card artwork or full celestial plates.
  static (Rect src, Rect dest) protectedContain(Rect src, Rect dest) {
    final scale = dest.width / src.width < dest.height / src.height
        ? dest.width / src.width
        : dest.height / src.height;
    final w = src.width * scale;
    final h = src.height * scale;
    final fitted = Rect.fromCenter(center: dest.center, width: w, height: h);
    return (src, fitted);
  }
}

/// EPIC-021 — Blur sigma tokens for glass surfaces.
library;

/// Backdrop and layer blur strengths.
abstract final class AppBlur {
  AppBlur._();

  static const double whisper = 8;
  static const double soft = 12;
  static const double glass = 18;
  static const double heavy = 24;
  static const double frosted = 32;
}

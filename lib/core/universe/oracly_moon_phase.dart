/// EPIC-005 — Moon phase inspired lighting — extremely subtle.
library;

import 'dart:math' show cos, pi, sin;

/// Approximate lunar phase — lighting influence only, never UI labels.
enum OraclyMoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

abstract final class OraclyMoonLighting {
  OraclyMoonLighting._();

  static const _synodicDays = 29.530588853;

  /// Known new moon anchor — 2000-01-06 18:14 UTC.
  static final _anchor = DateTime.utc(2000, 1, 6, 18, 14);

  /// Illumination [0 dark … 1 full].
  static double illumination(DateTime moment) {
    final days =
        moment.toUtc().difference(_anchor).inMilliseconds / 86400000.0;
    final phase = (days % _synodicDays) / _synodicDays;
    return 0.5 - 0.5 * cos(phase * 2 * pi);
  }

  static OraclyMoonPhase phase(DateTime moment) {
    final days = moment.toUtc().difference(_anchor).inMilliseconds / 86400000.0;
    final t = (days % _synodicDays) / _synodicDays;
    if (t < 0.0625) return OraclyMoonPhase.newMoon;
    if (t < 0.1875) return OraclyMoonPhase.waxingCrescent;
    if (t < 0.3125) return OraclyMoonPhase.firstQuarter;
    if (t < 0.4375) return OraclyMoonPhase.waxingGibbous;
    if (t < 0.5625) return OraclyMoonPhase.fullMoon;
    if (t < 0.6875) return OraclyMoonPhase.waningGibbous;
    if (t < 0.8125) return OraclyMoonPhase.lastQuarter;
    return OraclyMoonPhase.waningCrescent;
  }

  /// Soft silver-gold wash at full moon; deeper calm at new moon.
  static double atmosphericIntensity(double illumination) =>
      0.972 + illumination * 0.038;

  /// Crystal shimmer gently follows lunar light.
  static double crystalReflection(double illumination) =>
      0.985 + illumination * 0.028;

  /// Cool bias near new moon; warm whisper near full.
  static double warmthBias(double illumination) =>
      -0.022 + illumination * 0.044;

  /// Slow breathing tied to lunar position — nearly invisible.
  static double observatoryBreath(double illumination, double masterPhase) {
    final lunar = 0.5 + 0.5 * sin((illumination + masterPhase * 0.08) * pi * 2);
    return 0.988 + lunar * 0.018;
  }
}

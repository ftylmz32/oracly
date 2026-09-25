/// Phase 4 — ecliptic longitude normalization helpers.
library;

import '../models/zodiac_sign_id.dart';

abstract final class LongitudeMath {
  LongitudeMath._();

  /// Normalize to `[0, 360)`.
  static double normalize(double degrees) {
    var d = degrees % 360.0;
    if (d < 0) d += 360.0;
    return d;
  }

  /// Shortest signed angular separation in `(-180, 180]`.
  static double shortestSeparation(double a, double b) {
    var d = normalize(a - b);
    if (d > 180) d -= 360;
    return d;
  }

  static double absSeparation(double a, double b) =>
      shortestSeparation(a, b).abs();

  static ZodiacSignId signOf(double longitude) {
    final lon = normalize(longitude);
    final index = (lon / 30).floor().clamp(0, 11);
    return ZodiacSignId.values[index];
  }

  static double degreeWithinSign(double longitude) => normalize(longitude) % 30;
}

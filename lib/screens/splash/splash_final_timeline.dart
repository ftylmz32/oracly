/// Single-controller timeline helpers for the deliberate branded splash.
library;

abstract final class SplashFinalTimeline {
  SplashFinalTimeline._();

  /// Deliberate branded hold (~1.9s). Cap near 2s — never pad past bootstrap.
  static const durationMs = 1900;
  static const reducedMs = 1700;

  /// Maps global t in [0,1] to a segment progress.
  static double segment(double t, double start, double end) {
    if (end <= start) return 1;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double smooth(double x) {
    final v = x.clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }
}

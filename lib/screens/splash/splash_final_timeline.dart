/// Single-controller timeline helpers for final splash (~3.05s).
library;

abstract final class SplashFinalTimeline {
  SplashFinalTimeline._();

  static const durationMs = 3050;
  static const reducedMs = 1600;

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

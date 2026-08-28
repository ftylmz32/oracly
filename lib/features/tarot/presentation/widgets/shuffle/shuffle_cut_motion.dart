/// Cut-the-deck motion — split, then reform. Ritual, not a trick.
library;

import 'dart:ui' show Offset;

import 'dart:math' show pi, sin;

abstract final class ShuffleCutMotion {
  ShuffleCutMotion._();

  static const Duration duration = Duration(milliseconds: 920);

  /// Left packet slides away; right packet returns and the stack reforms.
  static Offset packetOffset({
    required int index,
    required int total,
    required double t,
  }) {
    final away = _split(t) * (1 - _reform(t));
    final left = index < total / 2;
    if (left) {
      return Offset(-38 * away, 2 * away);
    }
    return Offset(40 * away, -10 * away);
  }

  static double packetTilt(int index, int total, double t) {
    final left = index < total / 2;
    final wave = sin(_split(t) * pi) * 0.06;
    return left ? -wave : wave;
  }

  static double _split(double t) {
    if (t <= 0) return 0;
    if (t >= 0.46) return 1;
    return _smooth(t / 0.46);
  }

  static double _reform(double t) {
    if (t <= 0.42) return 0;
    if (t >= 1) return 1;
    return _smooth((t - 0.42) / 0.58);
  }

  static double _smooth(double x) {
    final c = x.clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }
}

/// OR speech tempo - preference only. Never a second personality.
library;

enum OrSpeechSpeed {
  slow,
  normal,
  fast;

  static const OrSpeechSpeed fallback = normal;

  String get wire => name;

  /// Device TTS rate multiplier. Fast stays clear (<= ~1.12x).
  double get deviceMul => switch (this) {
        slow => 0.86,
        normal => 1.0,
        fast => 1.12,
      };

  /// OpenAI / proxy speed multiplier. Capped in [applyProxy].
  double get proxyMul => switch (this) {
        slow => 0.90,
        normal => 1.0,
        fast => 1.12,
      };

  /// Final device rate - never cartoon-slow or unintelligible-fast.
  double applyDevice(double base) => (base * deviceMul).clamp(0.28, 0.62);

  /// Final provider speed - natural band only.
  double applyProxy(double base) => (base * proxyMul).clamp(0.85, 1.15);

  static OrSpeechSpeed parse(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    for (final id in OrSpeechSpeed.values) {
      if (id.wire == value || id.name.toLowerCase() == value) return id;
    }
    return fallback;
  }
}

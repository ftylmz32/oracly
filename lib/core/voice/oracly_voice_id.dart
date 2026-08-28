/// OR voice expression — timbre only. Same presence; never four products.
library;

enum OraclyVoiceId {
  warm,
  calm,
  deep,
  bright;

  static const OraclyVoiceId fallback = warm;

  String get wire => switch (this) {
        warm => 'warm',
        calm => 'calm',
        deep => 'deep',
        bright => 'bright',
      };

  /// Device-TTS engine register preference only — never shown in UI.
  bool get prefersLowerRegister =>
      this == OraclyVoiceId.calm || this == OraclyVoiceId.deep;

  /// Subtle device-TTS pitch only. Never a caricature.
  double get pitchMul => switch (this) {
        bright => 1.04,
        warm => 1.0,
        deep => 0.94,
        calm => 0.90,
      };

  double get rateMul => switch (this) {
        bright => 0.98,
        warm => 1.0,
        deep => 1.0,
        calm => 0.94,
      };

  static OraclyVoiceId parse(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    for (final id in OraclyVoiceId.values) {
      if (id.wire == value || id.name.toLowerCase() == value) return id;
    }
    return switch (value) {
      'female_natural' => warm,
      'male_calm' => calm,
      'male_natural' => deep,
      'female_soft' => bright,
      _ => fallback,
    };
  }
}

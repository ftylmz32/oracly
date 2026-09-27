/// Dream Phase 3 — what the dreamer stated that a dream reading must not
/// answer. Never a diagnosis: only what the words themselves say.
library;

enum DreamSafetyConcern {
  /// Current self-harm or suicidal intent stated about waking life.
  crisis('crisis'),

  /// Stated immediate danger or loss of safety right now.
  acuteDistress('acute_distress'),

  /// A real-life trauma the dreamer says actually happened.
  trauma('trauma'),

  /// Asking the dream to confirm an outside threat, spirit or voice is real.
  delusion('delusion'),

  /// Asking the dream to diagnose a psychiatric or medical condition.
  diagnosis('diagnosis');

  const DreamSafetyConcern(this.code);

  /// Bounded metadata code — the only thing that may be logged.
  final String code;
}

/// Thrown before any attempt, charge, provider call or storage when the
/// dreamer's own words need local safety guidance instead of a reading.
class DreamSafetyException implements Exception {
  const DreamSafetyException(this.concern);

  final DreamSafetyConcern concern;

  @override
  String toString() => 'DreamSafetyException(${concern.code})';
}

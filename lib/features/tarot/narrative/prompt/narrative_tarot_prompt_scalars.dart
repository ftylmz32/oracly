/// Phase 6C.2 — finite unit-interval and non-blank string helpers.
library;

abstract final class NarrativeTarotPromptScalars {
  NarrativeTarotPromptScalars._();

  static void requireUnit(String label, double value) {
    if (!value.isFinite || value < 0.0 || value > 1.0) {
      throw ArgumentError('$label must be finite in [0,1], got $value');
    }
  }

  static void requireUnitOpt(String label, double? value) {
    if (value != null) requireUnit(label, value);
  }

  static String requireNonBlank(String label, String value) {
    final t = value.trim();
    if (t.isEmpty) {
      throw ArgumentError('$label must be non-blank');
    }
    return t;
  }
}

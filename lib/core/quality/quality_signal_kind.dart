/// Funnel + opinion signals — no reading body, no quotes.
library;

enum QualitySignalKind {
  started,
  completed,
  abandoned,
  positive,
  negative,
  retry;

  String get wire => name;

  static QualitySignalKind? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

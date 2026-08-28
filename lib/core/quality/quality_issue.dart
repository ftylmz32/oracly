/// Shared quality issue labels — same wires as reading feedback.
library;

enum QualityIssue {
  missed,
  generic,
  unanswered,
  repetitive,
  inappropriate;

  String get wire => name;

  static QualityIssue? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

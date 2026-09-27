/// Merges optional user context into the AI narrative without changing storage.
library;

abstract final class DreamContextEnricher {
  DreamContextEnricher._();

  /// [heading] is ORACLY-owned scaffolding — callers pass it in the
  /// operation language (`DreamProviderEvidence`).
  static String narrativeForAi({
    required String narrative,
    List<String> tags = const [],
    String heading = '[Context]',
  }) {
    final trimmed = narrative.trim();
    final extras = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    if (extras.isEmpty) return trimmed;
    final buffer = StringBuffer(trimmed);
    buffer.writeln();
    buffer.writeln();
    buffer.writeln(heading);
    for (final extra in extras) {
      buffer.writeln('- $extra');
    }
    return buffer.toString();
  }
}

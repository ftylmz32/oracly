/// Pull named slices from a reading body without inventing text.
library;

abstract final class OracleFollowupSlices {
  OracleFollowupSlices._();

  static String? named(String body, List<String> labels) {
    for (final label in labels) {
      final match = RegExp(
        '$label\\s*:\\s*(.+)',
        caseSensitive: false,
      ).firstMatch(body);
      if (match != null) {
        final line = match.group(0)?.trim();
        if (line != null && line.isNotEmpty) return line;
      }
      final idx = body.toLowerCase().indexOf(label.toLowerCase());
      if (idx >= 0) {
        final cut = body.substring(idx).trim();
        if (cut.length > 24) {
          final end = cut.indexOf('\n\n');
          return end > 0 ? cut.substring(0, end).trim() : cut;
        }
      }
    }
    return null;
  }

  static String? symbolInQuestion(String q, List<String> names) {
    for (final name in names) {
      final token = name.trim().toLowerCase();
      if (token.length >= 3 && q.contains(token)) return name;
    }
    return null;
  }

  static bool matches(String q, List<String> keys) =>
      keys.any((k) => q.contains(k));
}

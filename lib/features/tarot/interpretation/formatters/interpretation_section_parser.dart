/// Splits markdown interpretation sections by heading.
library;

abstract final class InterpretationSectionParser {
  InterpretationSectionParser._();

  static Map<String, String> parse(String text) {
    final result = <String, String>{};
    final pattern = RegExp(r'^##?\s+(.+)$', multiLine: true);
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) return result;

    for (var i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)!.trim().toLowerCase();
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      result[title] = text.substring(start, end).trim();
    }
    return result;
  }

  static String? pick(Map<String, String> sections, List<String> keys) {
    for (final key in keys) {
      for (final entry in sections.entries) {
        if (entry.key.contains(key)) return entry.value;
      }
    }
    return null;
  }

  static String cardReadings(Map<String, String> sections) {
    final titled = pick(sections, [
      'kartların mesajı',
      'kartlar',
      'cards',
      'message of the cards',
      'послание карт',
    ]);
    if (titled != null && titled.trim().isNotEmpty) return titled;
    final blocks = [
      for (final entry in sections.entries)
        if (RegExp(r'^kart\s+\d+').hasMatch(entry.key))
          '${entry.key}\n${entry.value}'.trim(),
    ];
    if (blocks.isNotEmpty) return blocks.join('\n\n');
    return pick(sections, ['sağlık', 'health']) ?? '';
  }

  static String fromResultHealthOrRaw({
    required String health,
    String? rawText,
  }) {
    if (health.trim().isNotEmpty) return health;
    final raw = rawText?.trim() ?? '';
    if (raw.contains(' · ') &&
        (raw.contains('Düz') ||
            raw.contains('Ters') ||
            raw.contains('Upright') ||
            raw.contains('Reversed') ||
            raw.contains('Прям') ||
            raw.contains('Переверн'))) {
      return raw;
    }
    return '';
  }
}

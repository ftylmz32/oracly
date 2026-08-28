/// Long-term memory epistemic boundaries for OR.
///
/// FACT / OBSERVATION / INTERPRETATION / PREFERENCE stay distinct.
/// Symbolic reading never becomes FACT. Nothing is invented.
library;

enum OrMemoryKind {
  fact,
  observation,
  interpretation,
  preference,
}

abstract final class OrLongTermMemoryBoundaries {
  OrLongTermMemoryBoundaries._();

  /// Injected into styleHint only when long-term context is actually used.
  static const promptTr =
      'Uzun vadeli bağlam: FACT / OBSERVATION / INTERPRETATION / PREFERENCE '
      'ayrı dursun. Sembolik yorumu FACT yapma. Anı uydurma. '
      'İç bellek veya veritabanı dilinden bahsetme. '
      'Yalnızca bu turda ilgili olanı kullan.';

  static const promptEn =
      'Long-term context: keep FACT / OBSERVATION / INTERPRETATION / PREFERENCE '
      'distinct. Never turn symbolic interpretation into FACT. Invent no memory. '
      'Do not mention databases or internal memory mechanics. '
      'Use only what is relevant this turn.';

  static const promptRu =
      'Правила долгого контекста: '
      'FACT = явно данное пользователем. '
      'OBSERVATION = повторяющийся след открытий — не личность-FACT. '
      'INTERPRETATION = символическое чтение — не как твёрдый факт. '
      'PREFERENCE = тон — не приказ. '
      'Не превращай символическое в FACT. Не выдумывай память. '
      'Не говори о базах и внутренней механике. '
      'Используй только уместное в этом ходе.';

  static String tag(OrMemoryKind kind, String body) {
    final text = body.trim();
    if (text.isEmpty) return '';
    final label = switch (kind) {
      OrMemoryKind.fact => 'FACT',
      OrMemoryKind.observation => 'OBSERVATION',
      OrMemoryKind.interpretation => 'INTERPRETATION',
      OrMemoryKind.preference => 'PREFERENCE',
    };
    return '$label: $text';
  }

  /// True when any long-term bucket is present (not thread-only).
  static bool usesLongTerm({
    String? fact,
    String? observation,
    String? interpretation,
    String? preference,
  }) =>
      _ok(fact) ||
      _ok(observation) ||
      _ok(interpretation) ||
      _ok(preference);

  static bool _ok(String? s) => s != null && s.trim().isNotEmpty;
}

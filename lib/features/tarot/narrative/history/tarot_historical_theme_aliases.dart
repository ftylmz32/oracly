/// Exact token aliases → theme ids (TR/EN/RU). Phase 4A/4A.1 shared.
library;

abstract final class TarotHistoricalThemeAliases {
  TarotHistoricalThemeAliases._();

  /// Reviewed short aliases (length < 4) allowed for theme extraction only.
  /// ASCII `ask` is intentionally excluded (EN verb ambiguity).
  static const Map<String, String> shortTokenToThemeId = {'aşk': 'ilişki'};

  /// Normalized token → theme id. Built once from frozen alias lists.
  static final Map<String, String> tokenToThemeId = _build();

  static Map<String, String> _build() {
    const raw = <String, List<String>>{
      'karar': [
        'karar',
        'seçim',
        'secim',
        'decision',
        'choice',
        'choose',
        'решение',
        'выбор',
      ],
      'ilişki': [
        'ilişki',
        'iliski',
        'aşk',
        'partner',
        'relationship',
        'intimacy',
        'отношения',
        'партнер',
        'близость',
      ],
      'değişim': [
        'değişim',
        'degisim',
        'dönüşüm',
        'donusum',
        'change',
        'transition',
        'transformation',
        'изменение',
        'перемена',
        'трансформация',
      ],
      'sınır': [
        'sınır',
        'sinir',
        'mesafe',
        'boundary',
        'distance',
        'limits',
        'граница',
        'дистанция',
      ],
      'kariyer': [
        'kariyer',
        'meslek',
        'çalışma',
        'calisma',
        'career',
        'work',
        'profession',
        'карьера',
        'работа',
        'профессия',
      ],
      'iletişim': [
        'iletişim',
        'iletisim',
        'konuşma',
        'konusma',
        'mesaj',
        'communication',
        'conversation',
        'message',
        'общение',
        'разговор',
        'сообщение',
      ],
      'belirsizlik': [
        'belirsizlik',
        'kararsızlık',
        'kararsizlik',
        'uncertainty',
        'indecision',
        'confusion',
        'неопределенность',
        'сомнение',
      ],
      'özgüven': [
        'özgüven',
        'ozguven',
        'cesaret',
        'confidence',
        'courage',
        'уверенность',
        'смелость',
      ],
    };
    final out = <String, String>{};
    for (final e in raw.entries) {
      for (final alias in e.value) {
        out[alias] = e.key;
      }
    }
    // Short aliases also registered for documentation/lookup consistency.
    out.addAll(shortTokenToThemeId);
    return Map.unmodifiable(out);
  }
}

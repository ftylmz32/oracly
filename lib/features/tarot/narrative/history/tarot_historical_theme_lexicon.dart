/// Shared Phase 4 theme lexicon seam (aliases + keyword ids).
library;

import 'tarot_historical_text.dart';
import 'tarot_historical_theme_aliases.dart';
import 'tarot_historical_theme_keywords.dart';

abstract final class TarotHistoricalThemeLexicon {
  TarotHistoricalThemeLexicon._();

  /// Theme ids hit by exact aliases in [topicId] + [intentionSummary].
  static Set<String> themeIdsFromText({
    String? topicId,
    String? intentionSummary,
  }) {
    final themes = <String>{};
    _addFromGenericTokens(themes, topicId);
    _addFromGenericTokens(themes, intentionSummary);
    _addShortAliases(themes, topicId);
    _addShortAliases(themes, intentionSummary);

    // Exact theme-id as a whole normalized topic also counts.
    final topicNorm = TarotHistoricalText.normalizeTopic(topicId);
    if (topicNorm != null &&
        TarotHistoricalThemeKeywords.byThemeId.containsKey(topicNorm)) {
      themes.add(topicNorm);
    }
    return themes;
  }

  static void _addFromGenericTokens(Set<String> themes, String? raw) {
    for (final t in TarotHistoricalText.tokens(raw)) {
      final theme = TarotHistoricalThemeAliases.tokenToThemeId[t];
      if (theme != null) themes.add(theme);
    }
  }

  /// Reviewed short aliases only (`aşk` → ilişki). Does not lower token floor.
  static void _addShortAliases(Set<String> themes, String? raw) {
    for (final t in TarotHistoricalText.allWordTokens(raw)) {
      final theme = TarotHistoricalThemeAliases.shortTokenToThemeId[t];
      if (theme != null) themes.add(theme);
    }
  }

  static Set<String> keywordIdsForThemes(Iterable<String> themeIds) {
    final out = <String>{};
    for (final id in themeIds) {
      final kws = TarotHistoricalThemeKeywords.byThemeId[id];
      if (kws != null) out.addAll(kws);
    }
    return out;
  }
}

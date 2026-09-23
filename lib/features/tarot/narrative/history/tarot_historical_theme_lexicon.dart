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
    final tokens = <String>{
      ...TarotHistoricalText.tokens(topicId),
      ...TarotHistoricalText.tokens(intentionSummary),
    };
    final themes = <String>{};
    for (final t in tokens) {
      final theme = TarotHistoricalThemeAliases.tokenToThemeId[t];
      if (theme != null) themes.add(theme);
    }
    // Exact theme-id as a whole normalized topic also counts.
    final topicNorm = TarotHistoricalText.normalizeTopic(topicId);
    if (topicNorm != null &&
        TarotHistoricalThemeKeywords.byThemeId.containsKey(topicNorm)) {
      themes.add(topicNorm);
    }
    return themes;
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

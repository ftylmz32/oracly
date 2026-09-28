/// A catalogue dream image the dreamer never told.
library;

import '../../../core/l10n/app_locale.dart';
import '../../content/dream/data/dream_symbol_catalogue.dart';
import 'dream_analysis_facts.dart';
import 'dream_grounding_words.dart';
import 'dream_stated_feeling.dart';

abstract final class DreamInventedImage {
  DreamInventedImage._();

  /// Catalogue images exist in Turkish and English only, each checked in
  /// its own word forms. Russian prose is never matched here; it stays
  /// bound by the narrative grounding in the guard.
  static bool invents(String text, DreamAnalysisFacts facts) {
    if (facts.language == AppLocale.ru) return false;
    final english = facts.language == AppLocale.en;
    for (final item in DreamSymbolCatalogue.all) {
      final token = english ? item.token : item.tokenTr;
      if (!DreamGroundingWords.mentions(text, token, facts.language)) {
        continue;
      }
      if (DreamGroundingWords.mentions(facts.told, token, facts.language)) {
        continue;
      }
      if (DreamStatedFeeling.tells(item.id, facts.told)) continue;
      return true;
    }
    return false;
  }
}

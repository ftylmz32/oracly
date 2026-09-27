/// Provider-facing Dream evidence — the one boundary that turns a dream and
/// its on-device understanding into the request, in the operation language.
///
/// ORACLY-owned values (emotion chips, entry chips, guided-question labels,
/// the context heading) are rendered from stable ids in the operation
/// language. The dreamer's own text (narrative, guided answers) is passed as
/// written. Symbols are sent only as words the dreamer actually wrote in that
/// language; anything else is omitted — the narrative stays the evidence.
/// Request identity, payload and backend fingerprint all derive from this.
library;

import '../../../core/l10n/l10n.dart';
import '../../ai/production/contexts/reading_ai_context.dart';
import '../history/dream_history_evidence.dart';
import '../models/dream.dart';
import '../models/dream_emotion.dart';
import 'dream_analysis_fact_parts.dart';
import 'dream_context_enricher.dart';

abstract final class DreamProviderEvidence {
  DreamProviderEvidence._();

  static DreamAiContext context({
    required Dream dream,
    required DreamUnderstanding understanding,
    required String language,
    String? memorySummary,
    DreamHistoryContext history = DreamHistoryContext.empty,
  }) {
    return DreamAiContext(
      narrative: DreamContextEnricher.narrativeForAi(
        narrative: dream.narrative,
        tags: contextLines(dream, language),
        heading: _t('dream.read.join.context_heading', language),
      ),
      symbols: symbols(dream.narrative, understanding, language),
      emotions: emotions(dream, understanding, language),
      memorySummary: memorySummary,
      history: history.toPayload(),
      language: language,
    );
  }

  /// Entry chips and guided labels in the operation language, each guided
  /// answer verbatim. A record saved before structured entry context existed
  /// keeps its stored tags as historical text — never parsed back into ids.
  static List<String> contextLines(Dream dream, String language) {
    final entry = dream.entry;
    if (entry == null) return dream.tags;
    return [
      for (final chip in entry.chips) _t('dream.chip_${chip.name}', language),
      for (final answer in entry.guided.entries)
        '${_t('dream.guided_${answer.key.name}', language)}: ${answer.value}',
    ];
  }

  /// Chosen chips from their ids; narrative feeling words only where the
  /// dreamer wrote them in the operation language.
  static List<String> emotions(
    Dream dream,
    DreamUnderstanding understanding,
    String language,
  ) {
    final chipLabels = {for (final id in DreamEmotionId.values) id.labelTr};
    final lower = dream.narrative.toLowerCase();
    return _unique([
      for (final chip in dream.selectedEmotions)
        _t('dream.read.feeling_word.${chip.id.name}', language),
      for (final word in understanding.emotions)
        if (!chipLabels.contains(word) &&
            DreamAnalysisFactParts.observed(lower, word, language))
          word,
    ]);
  }

  /// TR: the catalogue label when the Turkish word was written. EN: the
  /// English token when it was written as a word. RU: none — there is no
  /// Russian catalogue, and TR/EN labels would be evidence never supplied.
  static List<String> symbols(
    String narrative,
    DreamUnderstanding understanding,
    String language,
  ) {
    if (language == AppLocale.ru) return const [];
    final lower = narrative.toLowerCase();
    final turkish = language == AppLocale.tr;
    return _unique([
      for (final symbol in understanding.symbols)
        if (DreamAnalysisFactParts.observed(
          lower,
          turkish ? symbol.label : symbol.token,
          language,
        ))
          turkish ? symbol.label : symbol.token,
    ]);
  }

  static String _t(String key, String language) =>
      OraclyL10n.t(key, languageCode: language);

  static List<String> _unique(List<String> values) {
    final seen = <String>{};
    return [
      for (final v in values)
        if (v.trim().isNotEmpty && seen.add(v.trim().toLowerCase())) v,
    ];
  }
}

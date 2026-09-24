/// Phase 6D — strict Narrative structured result parser.
library;

import 'narrative_tarot_result_bounds.dart';
import 'narrative_tarot_result_error.dart';
import 'narrative_tarot_result_parse_core.dart';
import 'narrative_tarot_result_parse_parts.dart';
import 'narrative_tarot_structured_result.dart';

abstract final class NarrativeTarotResultParser {
  NarrativeTarotResultParser._();

  static NarrativeTarotStructuredResult parse(Map<String, dynamic> data) {
    requireExactKeys(data, kResultTopKeys);
    final version = data['contractVersion'];
    if (version != NarrativeTarotResultBounds.contractVersion) {
      throw NarrativeTarotResultException(
        NarrativeTarotResultErrorKind.version,
        'contractVersion',
      );
    }
    final languageCode = requireString(data['languageCode']);
    if (!NarrativeTarotResultBounds.locales.contains(languageCode)) {
      throw NarrativeTarotResultException(
        NarrativeTarotResultErrorKind.locale,
        languageCode,
      );
    }
    final summary = requireBounded(
      data['summary'],
      NarrativeTarotResultBounds.summary,
    );
    final synthesis = requireBounded(
      data['synthesis'],
      NarrativeTarotResultBounds.synthesis,
    );
    final advice = requireBounded(
      data['advice'],
      NarrativeTarotResultBounds.advice,
    );
    final closing = requireBounded(
      data['closingMessage'],
      NarrativeTarotResultBounds.closingMessage,
    );
    final reflection = optionalBounded(
      data['reflectionPrompt'],
      NarrativeTarotResultBounds.reflectionPrompt,
    );
    final daily = optionalBounded(
      data['dailyFocus'],
      NarrativeTarotResultBounds.dailyFocus,
    );
    final result = NarrativeTarotStructuredResult(
      contractVersion: NarrativeTarotResultBounds.contractVersion,
      languageCode: languageCode,
      summary: summary,
      cardReadings: parseCardReadings(data['cardReadings']),
      synthesis: synthesis,
      relationshipInsights: parseRelationships(data['relationshipInsights']),
      recurringCardInsights: parseRecurringCards(data['recurringCardInsights']),
      recurringThemeInsights: parseThemes(data['recurringThemeInsights']),
      memoryInsights: parseMemory(data['memoryInsights']),
      lifeAreas: parseLifeAreas(data['lifeAreas']),
      advice: advice,
      reflectionPrompt: reflection,
      dailyFocus: daily,
      closingMessage: closing,
    );
    assertTotal(result);
    return result;
  }
}

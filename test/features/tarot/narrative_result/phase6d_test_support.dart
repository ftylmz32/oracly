/// Phase 6D — shared helpers for Narrative result/wire tests.
library;

import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_structured_result.dart';
import 'package:oracly_new/features/tarot/narrative/transport/narrative_tarot_wire_contract.dart';

String longProse([int min = 48]) {
  const base =
      'A calm reflective note about presence, choice, and gentle attention. ';
  if (base.length >= min) return base;
  return base + ('more. ' * ((min - base.length) ~/ 6 + 1));
}

Map<String, dynamic> validResultMap(TarotNarrativeRequest request) {
  return <String, dynamic>{
    'contractVersion': 1,
    'languageCode': request.languageCode,
    'summary': longProse(80),
    'cardReadings': [
      for (final c in request.cards)
        {
          'cardId': c.canonicalCardId,
          'positionKey': c.positionKey,
          'text': longProse(60),
        },
    ],
    'synthesis': longProse(90),
    'relationshipInsights': [
      for (final r in request.relationships.take(1))
        {
          'leftCardId': r.leftCardId,
          'rightCardId': r.rightCardId,
          'kind': r.kind.name,
          'text': longProse(50),
        },
    ],
    'recurringCardInsights': [
      for (final r in request.recurringCards.take(1))
        {'cardId': r.canonicalCardId, 'text': longProse(50)},
    ],
    'recurringThemeInsights': [
      for (final t in request.recurringThemes.take(1))
        {'themeIdOrLabel': t.themeIdOrLabel, 'text': longProse(50)},
    ],
    'memoryInsights':
        request.memory.included && request.memory.entries.isNotEmpty
            ? [
                {'memoryIndex': 0, 'text': longProse(50)},
              ]
            : <Map<String, dynamic>>[],
    'lifeAreas': [
      {'kind': 'love', 'text': longProse(50)},
    ],
    'advice': longProse(50),
    'reflectionPrompt': null,
    'dailyFocus': null,
    'closingMessage': longProse(50),
  };
}

Map<String, Object?> wirePayload(TarotNarrativeRequest request) {
  final input = NarrativeTarotPromptSerializer.serialize(request);
  return NarrativeTarotWireContract.payloadFor(input);
}

NarrativeTarotStructuredResult copyResult(
  NarrativeTarotStructuredResult r, {
  List<NarrativeTarotCardReading>? cardReadings,
  List<NarrativeTarotRelationshipInsight>? relationshipInsights,
  List<NarrativeTarotRecurringCardInsight>? recurringCardInsights,
  List<NarrativeTarotRecurringThemeInsight>? recurringThemeInsights,
  List<NarrativeTarotMemoryInsight>? memoryInsights,
  String? summary,
  String? languageCode,
}) {
  return NarrativeTarotStructuredResult(
    contractVersion: r.contractVersion,
    languageCode: languageCode ?? r.languageCode,
    summary: summary ?? r.summary,
    cardReadings: cardReadings ?? r.cardReadings,
    synthesis: r.synthesis,
    relationshipInsights: relationshipInsights ?? r.relationshipInsights,
    recurringCardInsights: recurringCardInsights ?? r.recurringCardInsights,
    recurringThemeInsights: recurringThemeInsights ?? r.recurringThemeInsights,
    memoryInsights: memoryInsights ?? r.memoryInsights,
    lifeAreas: r.lifeAreas,
    advice: r.advice,
    reflectionPrompt: r.reflectionPrompt,
    dailyFocus: r.dailyFocus,
    closingMessage: r.closingMessage,
  );
}

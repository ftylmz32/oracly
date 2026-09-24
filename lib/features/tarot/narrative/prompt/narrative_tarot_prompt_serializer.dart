/// Phase 6C — pure TarotNarrativeRequest → NarrativeTarotPromptInput.
library;

import '../evidence/narrative_card_evidence.dart';
import '../evidence/narrative_request.dart';
import 'narrative_tarot_prompt_evidence_parts.dart';
import 'narrative_tarot_prompt_input.dart';
import 'narrative_tarot_prompt_mappers.dart';
import 'narrative_tarot_prompt_parts.dart';
import 'narrative_tarot_prompt_validation.dart';

abstract final class NarrativeTarotPromptSerializer {
  NarrativeTarotPromptSerializer._();

  static NarrativeTarotPromptInput serialize(TarotNarrativeRequest request) {
    NarrativeTarotPromptValidation.validate(request);
    final lang = request.languageCode;
    final ordered = _cardsInInterpretationOrder(request);
    return NarrativeTarotPromptInput(
      narrativeTarotVersion: request.narrativeTarotVersion,
      serializerVersion: NarrativeTarotPromptInput.kSerializerVersion,
      languageCode: lang,
      question: NarrativePromptQuestion(
        text: request.question.rawText,
        topic: request.question.topic,
        kind: request.question.kind.name,
        hasRealQuestion: request.question.hasRealQuestion,
      ),
      spread: NarrativeTarotPromptMappers.spread(request.spread),
      cards: [
        for (final c in ordered) NarrativeTarotPromptMappers.card(c, lang),
      ],
      relationships: [
        for (final r in request.relationships)
          NarrativeTarotPromptMappers.relationship(r),
      ],
      recurringCards: [
        for (final r in request.recurringCards)
          NarrativeTarotPromptMappers.recurringCard(r),
      ],
      recurringThemes: [
        for (final t in request.recurringThemes)
          NarrativeTarotPromptMappers.recurringTheme(t),
      ],
      memory: NarrativeTarotPromptMappers.memory(request.memory),
      policy: NarrativePromptPolicy.v1,
    );
  }

  static List<TarotNarrativeCardEvidence> _cardsInInterpretationOrder(
    TarotNarrativeRequest request,
  ) {
    final byIndex = {
      for (final c in request.cards) c.positionIndex: c,
    };
    return [
      for (final i in request.spread.interpretationOrder) byIndex[i]!,
    ];
  }
}

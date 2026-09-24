/// Phase 6C — deterministic canonical representation (internal, not 6D JSON).
library;

import 'dart:convert';

import 'narrative_tarot_prompt_canonical_parts.dart';
import 'narrative_tarot_prompt_input.dart';

abstract final class NarrativeTarotPromptCanonical {
  NarrativeTarotPromptCanonical._();

  static Map<String, Object?> toMap(NarrativeTarotPromptInput input) {
    return sortMap({
      'narrativeTarotVersion': input.narrativeTarotVersion,
      'serializerVersion': input.serializerVersion,
      'languageCode': input.languageCode,
      'question': {
        'text': input.question.text,
        'topic': input.question.topic,
        'kind': input.question.kind,
        'hasRealQuestion': input.question.hasRealQuestion,
      },
      'spread': {
        'spreadId': input.spread.spreadId,
        'cardCount': input.spread.cardCount,
        'geometryHook': input.spread.geometryHook,
        'lengthBand': input.spread.lengthBand,
        'interpretationOrder': input.spread.interpretationOrder,
        'positions': [
          for (final p in input.spread.positions)
            {
              'positionKey': p.positionKey,
              'index': p.index,
              'role': p.role,
              'temporal': p.temporal,
            },
        ],
      },
      'cards': [for (final c in input.cards) cardMap(c)],
      'relationships': [
        for (final r in input.relationships)
          {
            'leftCardId': r.leftCardId,
            'rightCardId': r.rightCardId,
            'leftPositionKey': r.leftPositionKey,
            'rightPositionKey': r.rightPositionKey,
            'kind': r.kind,
            'strength': r.strength,
            if (r.note != null) 'note': r.note,
          },
      ],
      'recurringCards': [
        for (final r in input.recurringCards) recurringCardMap(r),
      ],
      'recurringThemes': [
        for (final t in input.recurringThemes)
          {
            'themeIdOrLabel': t.themeIdOrLabel,
            'supportCount': t.supportCount,
            'relatedCardIds': t.relatedCardIds,
            'relevanceToCurrentAsk': t.relevanceToCurrentAsk,
          },
      ],
      'memory': memoryMap(input.memory),
      'policy': {
        'version': input.policy.version,
        'rules': input.policy.rules,
      },
    });
  }

  static String encode(NarrativeTarotPromptInput input) {
    return jsonEncode(toMap(input));
  }
}

/// Phase 6C — canonical map helpers (sorted keys, list order preserved).
library;

import 'narrative_tarot_prompt_evidence_parts.dart';
import 'narrative_tarot_prompt_parts.dart';

Map<String, Object?> sortMap(Map<String, Object?> raw) {
  final keys = raw.keys.toList()..sort();
  final out = <String, Object?>{};
  for (final k in keys) {
    out[k] = canonicalize(raw[k]);
  }
  return out;
}

Object? canonicalize(Object? v) {
  if (v is Map) {
    return sortMap(Map<String, Object?>.from(v));
  }
  if (v is List) {
    return [for (final e in v) canonicalize(e)];
  }
  return v;
}

Map<String, Object?> cardMap(NarrativePromptCard c) {
  return sortMap({
    'canonicalCardId': c.canonicalCardId,
    'displayName': c.displayName,
    'isReversed': c.isReversed,
    'positionKey': c.positionKey,
    'positionIndex': c.positionIndex,
    'coreMeaning': c.coreMeaning,
    'orientationExpression': c.orientationExpression,
    'keywordIds': c.keywordIds,
    'symbolTags': c.symbolTags,
    'transforms': c.transforms,
    if (c.light != null) 'light': c.light,
    if (c.shadow != null) 'shadow': c.shadow,
    if (c.tension != null) 'tension': c.tension,
    if (c.desire != null) 'desire': c.desire,
    if (c.fear != null) 'fear': c.fear,
    if (c.relationshipDynamic != null)
      'relationshipDynamic': c.relationshipDynamic,
    if (c.decisionDynamic != null) 'decisionDynamic': c.decisionDynamic,
    if (c.actionDirection != null) 'actionDirection': c.actionDirection,
  });
}

Map<String, Object?> recurringCardMap(NarrativePromptRecurringCard r) {
  return sortMap({
    'canonicalCardId': r.canonicalCardId,
    'occurrenceCount': r.occurrenceCount,
    'contextsOverlap': r.contextsOverlap,
    if (r.overlapSummaryKey != null) 'overlapSummaryKey': r.overlapSummaryKey,
    'occurrences': [
      for (final o in r.occurrences)
        sortMap({
          'occurredAtUtc': o.occurredAtUtc,
          'spreadId': o.spreadId,
          'positionKey': o.positionKey,
          'orientationKnown': o.orientationKnown,
          'isReversed': o.isReversed,
          if (o.intentionSummary != null)
            'intentionSummary': o.intentionSummary,
        }),
    ],
  });
}

Map<String, Object?> memoryMap(NarrativePromptMemory m) {
  return sortMap({
    'included': m.included,
    'priorReadingCount': m.priorReadingCount,
    'entries': [
      for (final e in m.entries)
        {
          'kind': e.kind,
          'contentForModel': e.contentForModel,
          if (e.sourceType != null) 'sourceType': e.sourceType,
          if (e.occurredAtUtc != null) 'occurredAtUtc': e.occurredAtUtc,
          if (e.confidence != null) 'confidence': e.confidence,
          if (e.epistemic != null) 'epistemic': e.epistemic,
        },
    ],
  });
}

/// Corpus projection + compare helpers (Phase 4D).
library;

import 'dart:convert';

import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';

Map<String, dynamic> phase4Projection(TarotNarrativeRequest r) {
  return {
    'memory': {
      'included': r.memory.included,
      'omitReason': r.memory.omitReason,
      'priorReadingCount': r.memory.priorReadingCount,
      'recentCardNames': r.memory.recentCardNames,
      'recurringThemeLabels': r.memory.recurringThemeLabels,
      'entries': [
        for (final e in r.memory.entries)
          {
            'evidenceRef': e.evidenceRef,
            'kind': e.kind.name,
            'contentForModel': e.contentForModel,
            'sourceType': e.sourceType,
            'sourceId': e.sourceId,
            'occurredAt': e.occurredAt?.toUtc().toIso8601String(),
            'confidence': e.confidence,
            'epistemic': e.epistemic?.name,
          },
      ],
    },
    'recurringCards': [
      for (final c in r.recurringCards)
        {
          'evidenceId': c.evidenceId,
          'canonicalCardId': c.canonicalCardId,
          'occurrenceCount': c.occurrenceCount,
          'contextsOverlap': c.contextsOverlap,
          'overlapSummaryKey': c.overlapSummaryKey,
          'occurrences': [
            for (final o in c.occurrences)
              {
                'readingId': o.readingId,
                'at': o.at.toUtc().toIso8601String(),
                'spreadId': o.spreadId,
                'positionKey': o.positionKey,
                'isReversed': o.isReversed,
                'orientationKnown': o.orientationKnown,
                'intentionSummary': o.intentionSummary,
              },
          ],
        },
    ],
    'recurringThemes': [
      for (final t in r.recurringThemes)
        {
          'evidenceId': t.evidenceId,
          'themeIdOrLabel': t.themeIdOrLabel,
          'supportCount': t.supportCount,
          'supportingReadingIds': t.supportingReadingIds,
          'relatedCardIds': t.relatedCardIds,
          'relevanceToCurrentAsk': t.relevanceToCurrentAsk,
        },
    ],
  };
}

Map<String, dynamic> phase3Projection(TarotNarrativeRequest r) {
  return {
    'narrativeTarotVersion': r.narrativeTarotVersion,
    'languageCode': r.languageCode,
    'sessionId': r.sessionId,
    'readingId': r.readingId,
    'question': {
      'rawText': r.question.rawText,
      'topic': r.question.topic,
      'kind': r.question.kind.name,
      'hasRealQuestion': r.question.hasRealQuestion,
    },
    'spreadId': r.spread.spreadId,
    'cardIds': [for (final c in r.cards) c.canonicalCardId],
    'relationshipIds': [for (final x in r.relationships) x.evidenceId],
    'relationshipKinds': [for (final x in r.relationships) x.kind.name],
    'relationshipStrengths': [for (final x in r.relationships) x.strength],
    'bounds': {
      'maxPriorReadingsScanned': r.bounds.maxPriorReadingsScanned,
      'maxRecurringOccurrencesListed': r.bounds.maxRecurringOccurrencesListed,
      'maxRelationships': r.bounds.maxRelationships,
      'maxMemoryChars': r.bounds.maxMemoryChars,
      'maxThemeLabels': r.bounds.maxThemeLabels,
    },
  };
}

void expectPhase4Equal(Map expected, Map actual) {
  final e = jsonEncode(expected);
  final a = jsonEncode(actual);
  if (e != a) {
    _deepEqual(expected, actual, r'\$');
  }
}

void _deepEqual(dynamic expected, dynamic actual, String path) {
  if (expected is Map && actual is Map) {
    if (expected.keys.toSet() != actual.keys.toSet()) {
      throw TestFailure('key mismatch at $path');
    }
    for (final k in expected.keys) {
      _deepEqual(expected[k], actual[k], '$path.$k');
    }
    return;
  }
  if (expected is List && actual is List) {
    if (expected.length != actual.length) {
      throw TestFailure('len mismatch at $path');
    }
    for (var i = 0; i < expected.length; i++) {
      _deepEqual(expected[i], actual[i], '$path[$i]');
    }
    return;
  }
  if (expected is num && actual is num) {
    if ((expected.toDouble() - actual.toDouble()).abs() > 1e-9) {
      throw TestFailure('num mismatch at $path: $expected vs $actual');
    }
    return;
  }
  if (expected != actual) {
    throw TestFailure('mismatch at $path: $expected vs $actual');
  }
}

class TestFailure implements Exception {
  TestFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

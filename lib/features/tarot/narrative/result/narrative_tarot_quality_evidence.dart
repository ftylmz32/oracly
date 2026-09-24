/// Phase 6D — quality validator evidence binding helpers.
library;

import '../evidence/narrative_request.dart';
import 'narrative_tarot_result_error.dart';
import 'narrative_tarot_structured_result.dart';

Never qFail(NarrativeTarotResultErrorKind kind, [String msg = '']) {
  throw NarrativeTarotResultException(kind, msg);
}

void validateCardCoverage(
  TarotNarrativeRequest request,
  NarrativeTarotStructuredResult result,
) {
  if (result.cardReadings.length != request.cards.length) {
    qFail(NarrativeTarotResultErrorKind.cardCoverage, 'count');
  }
  final expected = {
    for (final c in request.cards) c.canonicalCardId: c.positionKey,
  };
  final seen = <String>{};
  for (final r in result.cardReadings) {
    if (expected[r.cardId] != r.positionKey || !seen.add(r.cardId)) {
      qFail(NarrativeTarotResultErrorKind.cardCoverage, r.cardId);
    }
  }
  if (seen.length != expected.length) {
    qFail(NarrativeTarotResultErrorKind.cardCoverage, 'missing');
  }
}

void validateRelationships(
  TarotNarrativeRequest request,
  NarrativeTarotStructuredResult result,
) {
  if (request.relationships.isEmpty && result.relationshipInsights.isNotEmpty) {
    qFail(NarrativeTarotResultErrorKind.relationshipEvidence, 'empty');
  }
  final allowed = {
    for (final r in request.relationships)
      '${r.leftCardId}|${r.rightCardId}|${r.kind.name}',
  };
  final seen = <String>{};
  for (final r in result.relationshipInsights) {
    final key = '${r.leftCardId}|${r.rightCardId}|${r.kind}';
    if (!allowed.contains(key) || !seen.add(key)) {
      qFail(NarrativeTarotResultErrorKind.relationshipEvidence, key);
    }
  }
}

void validateRecurrence(
  TarotNarrativeRequest request,
  NarrativeTarotStructuredResult result,
) {
  if (request.recurringCards.isEmpty &&
      result.recurringCardInsights.isNotEmpty) {
    qFail(NarrativeTarotResultErrorKind.recurrenceEvidence, 'cards');
  }
  if (request.recurringThemes.isEmpty &&
      result.recurringThemeInsights.isNotEmpty) {
    qFail(NarrativeTarotResultErrorKind.recurrenceEvidence, 'themes');
  }
  final cards = {for (final c in request.recurringCards) c.canonicalCardId};
  final themes = {for (final t in request.recurringThemes) t.themeIdOrLabel};
  final seenC = <String>{};
  for (final r in result.recurringCardInsights) {
    if (!cards.contains(r.cardId) || !seenC.add(r.cardId)) {
      qFail(NarrativeTarotResultErrorKind.recurrenceEvidence, r.cardId);
    }
  }
  final seenT = <String>{};
  for (final r in result.recurringThemeInsights) {
    if (!themes.contains(r.themeIdOrLabel) || !seenT.add(r.themeIdOrLabel)) {
      qFail(NarrativeTarotResultErrorKind.recurrenceEvidence, r.themeIdOrLabel);
    }
  }
}

void validateMemory(
  TarotNarrativeRequest request,
  NarrativeTarotStructuredResult result,
) {
  if (!request.memory.included && result.memoryInsights.isNotEmpty) {
    qFail(NarrativeTarotResultErrorKind.memoryEvidence, 'excluded');
  }
  final max = request.memory.entries.length;
  final global = <int>{};
  for (final m in result.memoryInsights) {
    if (m.memoryIndices.isEmpty) {
      qFail(NarrativeTarotResultErrorKind.memoryEvidence, 'empty');
    }
    for (var i = 0; i < m.memoryIndices.length; i++) {
      final idx = m.memoryIndices[i];
      if (idx < 0 || idx >= max || !global.add(idx)) {
        qFail(NarrativeTarotResultErrorKind.memoryEvidence, '$idx');
      }
      if (i > 0 && idx <= m.memoryIndices[i - 1]) {
        qFail(NarrativeTarotResultErrorKind.memoryEvidence, 'unsorted');
      }
    }
  }
}

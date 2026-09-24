/// Phase 6D — private-id leak scan for Narrative results.
library;

import '../evidence/narrative_request.dart';
import 'narrative_tarot_quality_evidence.dart';
import 'narrative_tarot_result_error.dart';
import 'narrative_tarot_structured_result.dart';

Iterable<String> visibleTexts(NarrativeTarotStructuredResult r) sync* {
  yield r.summary;
  yield r.synthesis;
  yield r.advice;
  yield r.closingMessage;
  if (r.reflectionPrompt != null) yield r.reflectionPrompt!;
  if (r.dailyFocus != null) yield r.dailyFocus!;
  for (final c in r.cardReadings) {
    yield c.text;
  }
  for (final x in r.relationshipInsights) {
    yield x.text;
  }
  for (final x in r.recurringCardInsights) {
    yield x.text;
  }
  for (final x in r.recurringThemeInsights) {
    yield x.text;
  }
  for (final x in r.memoryInsights) {
    yield x.text;
  }
  for (final x in r.lifeAreas) {
    yield x.text;
  }
}

final _tokenPatterns = RegExp(
  r'\b(rel_\d+|rec_card_\d+|rec_theme_\d+|mem_\d+)\b',
  caseSensitive: false,
);

void rejectPrivateLeaks(
  TarotNarrativeRequest request,
  NarrativeTarotStructuredResult result,
) {
  final secrets = <String>{
    request.sessionId,
    request.readingId,
    for (final r in request.relationships) r.evidenceId,
    for (final c in request.recurringCards) c.evidenceId,
    for (final t in request.recurringThemes) ...[
      t.evidenceId,
      ...t.supportingReadingIds,
    ],
    for (final c in request.recurringCards)
      for (final o in c.occurrences) o.readingId,
    for (final e in request.memory.entries) ...[
      e.evidenceRef,
      if (e.sourceId != null) e.sourceId!,
    ],
  }.where((s) => s.trim().isNotEmpty).toSet();

  for (final text in visibleTexts(result)) {
    if (_tokenPatterns.hasMatch(text)) {
      qFail(NarrativeTarotResultErrorKind.privateIdentifier, 'token');
    }
    for (final s in secrets) {
      if (text.contains(s)) {
        qFail(NarrativeTarotResultErrorKind.privateIdentifier);
      }
    }
  }
}

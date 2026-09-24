/// Phase 6D — list field parsers for structured result.
library;

import 'narrative_tarot_result_bounds.dart';
import 'narrative_tarot_result_error.dart';
import 'narrative_tarot_result_parse_core.dart';
import 'narrative_tarot_structured_result.dart';

List<NarrativeTarotCardReading> parseCardReadings(Object? raw) {
  return [
    for (final m in requireMapList(raw))
      () {
        requireExactKeys(m, {'cardId', 'positionKey', 'text'});
        return NarrativeTarotCardReading(
          cardId: requireString(m['cardId']),
          positionKey: requireString(m['positionKey']),
          text: requireBounded(m['text'], NarrativeTarotResultBounds.cardReading),
        );
      }(),
  ];
}

List<NarrativeTarotRelationshipInsight> parseRelationships(Object? raw) {
  return [
    for (final m in requireMapList(raw))
      () {
        requireExactKeys(m, {'leftCardId', 'rightCardId', 'kind', 'text'});
        return NarrativeTarotRelationshipInsight(
          leftCardId: requireString(m['leftCardId']),
          rightCardId: requireString(m['rightCardId']),
          kind: requireString(m['kind']),
          text: requireBounded(
            m['text'],
            NarrativeTarotResultBounds.relationshipInsight,
          ),
        );
      }(),
  ];
}

List<NarrativeTarotRecurringCardInsight> parseRecurringCards(Object? raw) {
  return [
    for (final m in requireMapList(raw))
      () {
        requireExactKeys(m, {'cardId', 'text'});
        return NarrativeTarotRecurringCardInsight(
          cardId: requireString(m['cardId']),
          text: requireBounded(
            m['text'],
            NarrativeTarotResultBounds.recurringCardInsight,
          ),
        );
      }(),
  ];
}

List<NarrativeTarotRecurringThemeInsight> parseThemes(Object? raw) {
  return [
    for (final m in requireMapList(raw))
      () {
        requireExactKeys(m, {'themeIdOrLabel', 'text'});
        return NarrativeTarotRecurringThemeInsight(
          themeIdOrLabel: requireString(m['themeIdOrLabel']),
          text: requireBounded(
            m['text'],
            NarrativeTarotResultBounds.recurringThemeInsight,
          ),
        );
      }(),
  ];
}

List<NarrativeTarotMemoryInsight> parseMemory(Object? raw) {
  return [
    for (final m in requireMapList(raw))
      () {
        requireExactKeys(m, {'memoryIndex', 'text'});
        final idx = m['memoryIndex'];
        if (idx is! int || idx < 0) {
          fail(NarrativeTarotResultErrorKind.schema, 'memoryIndex');
        }
        return NarrativeTarotMemoryInsight(
          memoryIndex: idx,
          text: requireBounded(
            m['text'],
            NarrativeTarotResultBounds.memoryInsight,
          ),
        );
      }(),
  ];
}

List<NarrativeTarotLifeArea> parseLifeAreas(Object? raw) {
  final list = requireMapList(raw);
  if (list.length > NarrativeTarotResultBounds.maxLifeAreas) {
    fail(NarrativeTarotResultErrorKind.bounds, 'lifeAreas');
  }
  final seen = <String>{};
  return [
    for (final m in list)
      () {
        requireExactKeys(m, {'kind', 'text'});
        final kind = requireString(m['kind']);
        if (!NarrativeTarotResultBounds.lifeAreaKinds.contains(kind)) {
          fail(NarrativeTarotResultErrorKind.schema, kind);
        }
        if (!seen.add(kind)) {
          fail(NarrativeTarotResultErrorKind.duplicate, kind);
        }
        return NarrativeTarotLifeArea(
          kind: kind,
          text: requireBounded(m['text'], NarrativeTarotResultBounds.lifeArea),
        );
      }(),
  ];
}

void assertTotal(NarrativeTarotStructuredResult r) {
  var n = r.summary.length +
      r.synthesis.length +
      r.advice.length +
      r.closingMessage.length +
      (r.reflectionPrompt?.length ?? 0) +
      (r.dailyFocus?.length ?? 0);
  for (final c in r.cardReadings) {
    n += c.text.length;
  }
  for (final x in r.relationshipInsights) {
    n += x.text.length;
  }
  for (final x in r.recurringCardInsights) {
    n += x.text.length;
  }
  for (final x in r.recurringThemeInsights) {
    n += x.text.length;
  }
  for (final x in r.memoryInsights) {
    n += x.text.length;
  }
  for (final x in r.lifeAreas) {
    n += x.text.length;
  }
  if (n > NarrativeTarotResultBounds.totalVisible) {
    fail(NarrativeTarotResultErrorKind.bounds, 'total');
  }
}

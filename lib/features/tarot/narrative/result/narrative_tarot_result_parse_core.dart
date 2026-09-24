/// Phase 6D — parser key/bounds primitives.
library;

import 'narrative_tarot_result_error.dart';

const kResultTopKeys = {
  'contractVersion',
  'languageCode',
  'summary',
  'cardReadings',
  'synthesis',
  'relationshipInsights',
  'recurringCardInsights',
  'recurringThemeInsights',
  'memoryInsights',
  'lifeAreas',
  'advice',
  'reflectionPrompt',
  'dailyFocus',
  'closingMessage',
};

Never fail(NarrativeTarotResultErrorKind kind, [String msg = '']) {
  throw NarrativeTarotResultException(kind, msg);
}

void requireExactKeys(Map<String, dynamic> map, Set<String> allowed) {
  if (map.length != allowed.length) {
    fail(NarrativeTarotResultErrorKind.schema, 'key count');
  }
  for (final k in map.keys) {
    if (!allowed.contains(k)) {
      fail(NarrativeTarotResultErrorKind.schema, k);
    }
  }
  for (final k in allowed) {
    if (!map.containsKey(k)) {
      fail(NarrativeTarotResultErrorKind.schema, 'missing $k');
    }
  }
}

String requireString(Object? v) {
  if (v is! String) fail(NarrativeTarotResultErrorKind.schema, 'string');
  return v;
}

String requireBounded(Object? v, int max) {
  final s = requireString(v);
  if (s.trim().isEmpty || s.length > max) {
    fail(NarrativeTarotResultErrorKind.bounds, 'text');
  }
  return s;
}

String? optionalBounded(Object? v, int max) {
  if (v == null) return null;
  return requireBounded(v, max);
}

List<Map<String, dynamic>> requireMapList(Object? v) {
  if (v is! List) fail(NarrativeTarotResultErrorKind.schema, 'list');
  return [
    for (final e in v)
      e is Map<String, dynamic>
          ? e
          : (e is Map
              ? Map<String, dynamic>.from(e)
              : fail(NarrativeTarotResultErrorKind.schema, 'map')),
  ];
}

/// Phase 6E.3 — Narrative prose quality (deterministic-future sentinels).
library;

import 'narrative_tarot_result_error.dart';
import 'narrative_tarot_structured_result.dart';

abstract final class NarrativeTarotProseQuality {
  NarrativeTarotProseQuality._();

  static final _en = <RegExp>[
    RegExp(r'\bfuture\s+promises\b', caseSensitive: false),
    RegExp(r'\bthe\s+future\s+promises\b', caseSensitive: false),
    RegExp(r'\bwill\s+definitely\b', caseSensitive: false),
    RegExp(r'\bwill\s+certainly\b', caseSensitive: false),
    RegExp(r'\binevitably\b', caseSensitive: false),
    RegExp(r'\bis\s+guaranteed\s+to\b', caseSensitive: false),
    RegExp(r'\bwill\s+lead\s+to\b', caseSensitive: false),
  ];

  static final _tr = <RegExp>[
    RegExp(r'\bkesinlikle\s+olacak\b', caseSensitive: false),
    RegExp(r'\bkesin\s+olacak\b', caseSensitive: false),
    RegExp(r'\bmutlaka\s+olacak\b', caseSensitive: false),
    RegExp(r'\bkaçınılmaz\s+olarak\b', caseSensitive: false),
    RegExp(r'\bgaranti(?:dir|li)?\b', caseSensitive: false),
  ];

  static final _ru = <RegExp>[
    RegExp(r'\bбудущее\s+обещает\b', caseSensitive: false),
    RegExp(r'\bобязательно\s+произойд', caseSensitive: false),
    RegExp(r'\bнеизбежно\b', caseSensitive: false),
    RegExp(r'\bгарантированно\b', caseSensitive: false),
    RegExp(r'\bточно\s+произойд', caseSensitive: false),
  ];

  static String visibleProse(NarrativeTarotStructuredResult r) {
    final b = StringBuffer()
      ..writeln(r.summary)
      ..writeln(r.synthesis)
      ..writeln(r.advice)
      ..writeln(r.closingMessage);
    if (r.reflectionPrompt != null) b.writeln(r.reflectionPrompt);
    if (r.dailyFocus != null) b.writeln(r.dailyFocus);
    for (final c in r.cardReadings) {
      b.writeln(c.text);
    }
    for (final x in r.relationshipInsights) {
      b.writeln(x.text);
    }
    for (final x in r.recurringCardInsights) {
      b.writeln(x.text);
    }
    for (final x in r.recurringThemeInsights) {
      b.writeln(x.text);
    }
    for (final x in r.memoryInsights) {
      b.writeln(x.text);
    }
    for (final x in r.lifeAreas) {
      b.writeln(x.text);
    }
    return b.toString();
  }

  static List<RegExp> _patterns(String languageCode) {
    if (languageCode == 'tr') return _tr;
    if (languageCode == 'ru') return _ru;
    return _en;
  }

  /// Returns matching pattern source, or null when prose is acceptable.
  static String? firstDeterministicFutureHit(
    String text, {
    required String languageCode,
  }) {
    for (final re in _patterns(languageCode)) {
      if (re.hasMatch(text)) return re.pattern;
    }
    return null;
  }

  static void validate(NarrativeTarotStructuredResult result) {
    final hit = firstDeterministicFutureHit(
      visibleProse(result),
      languageCode: result.languageCode,
    );
    if (hit != null) {
      throw NarrativeTarotResultException(
        NarrativeTarotResultErrorKind.deterministicFuture,
        hit,
      );
    }
  }
}

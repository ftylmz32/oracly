/// Phase 6C.2 — canonical request bounds + operational identity.
library;

import '../evidence/narrative_request.dart';

abstract final class NarrativeTarotPromptBoundsChecks {
  NarrativeTarotPromptBoundsChecks._();

  static void requestBounds(TarotNarrativeRequest request) {
    final b = request.bounds;
    final d = RequestBounds.defaults;
    _cap('maxPriorReadingsScanned', b.maxPriorReadingsScanned,
        d.maxPriorReadingsScanned);
    _cap(
      'maxRecurringOccurrencesListed',
      b.maxRecurringOccurrencesListed,
      d.maxRecurringOccurrencesListed,
    );
    _cap('maxRelationships', b.maxRelationships, d.maxRelationships);
    _cap('maxMemoryChars', b.maxMemoryChars, d.maxMemoryChars);
    _cap('maxThemeLabels', b.maxThemeLabels, d.maxThemeLabels);
  }

  static void readingIdentity(TarotNarrativeRequest request) {
    if (request.sessionId.trim().isEmpty) {
      throw ArgumentError('sessionId must be non-empty');
    }
    if (request.readingId.trim().isEmpty) {
      throw ArgumentError('readingId must be non-empty');
    }
  }

  static void _cap(String name, int value, int max) {
    if (value < 0 || value > max) {
      throw ArgumentError('$name $value outside 0..$max');
    }
  }
}

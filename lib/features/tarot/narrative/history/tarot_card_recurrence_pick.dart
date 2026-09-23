/// Internal helpers for card occurrence pick / ranking (Phase 4A).
library;

import 'tarot_historical_models.dart';

abstract final class TarotCardRecurrencePick {
  TarotCardRecurrencePick._();

  /// At most one occurrence per (reading, card); deterministic pick.
  static TarotHistoricalCardOccurrence? pick(
    TarotHistoricalReadingRecord record,
    String canonicalCardId,
  ) {
    final candidates = <TarotHistoricalCardOccurrence>[];
    for (final c in record.cards) {
      if (c.canonicalCardId.isEmpty) continue;
      if (c.canonicalCardId != canonicalCardId) continue;
      candidates.add(c);
    }
    if (candidates.isEmpty) return null;
    candidates.sort(compareOccurrences);
    return candidates.first;
  }

  static int compareOccurrences(
    TarotHistoricalCardOccurrence a,
    TarotHistoricalCardOccurrence b,
  ) {
    final ai = a.positionIndex;
    final bi = b.positionIndex;
    if (ai != null && bi != null) {
      final byIndex = ai.compareTo(bi);
      if (byIndex != 0) return byIndex;
    } else if (ai != null) {
      return -1;
    } else if (bi != null) {
      return 1;
    }
    final apk = a.positionKey;
    final bpk = b.positionKey;
    if (apk != null && bpk != null) {
      final byKey = apk.compareTo(bpk);
      if (byKey != 0) return byKey;
    } else if (apk != null) {
      return -1;
    } else if (bpk != null) {
      return 1;
    }
    if (a.orientationKnown != b.orientationKnown) {
      return a.orientationKnown ? -1 : 1;
    }
    if (a.isReversed != b.isReversed) {
      return a.isReversed ? 1 : -1;
    }
    return 0;
  }
}

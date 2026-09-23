/// Pure eligibility / lookback policy for historical Tarot FACT rows (Phase 4A).
library;

import '../evidence/narrative_request.dart';
import 'tarot_historical_models.dart';

abstract final class TarotHistoricalEligibility {
  TarotHistoricalEligibility._();

  static const lookback = Duration(days: 90);

  /// Owner + current-exclusion + time filter → newest-first → scan bound.
  static List<TarotHistoricalReadingRecord> eligibleTarotReadings({
    required List<TarotHistoricalReadingRecord> readings,
    required String currentReadingId,
    required String? currentSessionId,
    required String? currentOwnerId,
    required DateTime now,
    required RequestBounds bounds,
  }) {
    final nowUtc = now.toUtc();
    final filtered = <TarotHistoricalReadingRecord>[];
    for (final r in readings) {
      if (!_structurallyValid(r)) continue;
      if (!_ownerOk(r.ownerId, currentOwnerId)) continue;
      if (_isCurrent(r, currentReadingId, currentSessionId)) continue;
      if (!_withinLookback(r.occurredAt, nowUtc)) continue;
      filtered.add(r);
    }
    filtered.sort(_compareNewestFirst);
    final max = bounds.maxPriorReadingsScanned;
    if (max <= 0) return const [];
    final taken = filtered.length <= max ? filtered : filtered.sublist(0, max);
    return List<TarotHistoricalReadingRecord>.unmodifiable(taken);
  }

  static bool _structurallyValid(TarotHistoricalReadingRecord r) {
    if (r.readingId.trim().isEmpty) return false;
    if (r.spreadId.trim().isEmpty) return false;
    return true;
  }

  static bool _ownerOk(String? historicalOwnerId, String? currentOwnerId) {
    if (currentOwnerId != null) {
      return historicalOwnerId != null && historicalOwnerId == currentOwnerId;
    }
    return historicalOwnerId == null;
  }

  static bool _isCurrent(
    TarotHistoricalReadingRecord r,
    String currentReadingId,
    String? currentSessionId,
  ) {
    if (r.readingId == currentReadingId) return true;
    if (currentSessionId != null &&
        r.sessionId != null &&
        r.sessionId == currentSessionId) {
      return true;
    }
    return false;
  }

  static bool _withinLookback(DateTime occurredAt, DateTime nowUtc) {
    final occurredUtc = occurredAt.toUtc();
    if (occurredUtc.compareTo(nowUtc) > 0) return false;
    return nowUtc.difference(occurredUtc) <= lookback;
  }

  static int _compareNewestFirst(
    TarotHistoricalReadingRecord a,
    TarotHistoricalReadingRecord b,
  ) {
    final byTime = b.occurredAt.toUtc().compareTo(a.occurredAt.toUtc());
    if (byTime != 0) return byTime;
    return a.readingId.compareTo(b.readingId);
  }
}

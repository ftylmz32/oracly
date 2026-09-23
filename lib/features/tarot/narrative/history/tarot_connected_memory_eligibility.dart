/// Pure connected-memory eligibility / lookback / dedupe (Phase 4B).
library;

import '../evidence/narrative_request.dart';
import 'tarot_connected_memory_models.dart';
import 'tarot_historical_eligibility.dart';

abstract final class TarotConnectedMemoryEligibility {
  TarotConnectedMemoryEligibility._();

  static List<TarotConnectedMemoryRecord> eligible({
    required List<TarotConnectedMemoryRecord> records,
    required TarotNarrativeRequest base,
    required DateTime now,
  }) {
    final nowUtc = now.toUtc();
    final filtered = <TarotConnectedMemoryRecord>[];
    for (final r in records) {
      if (r.sourceId.trim().isEmpty) continue;
      if (!_withinLookback(r.occurredAt, nowUtc)) continue;
      if (_isCurrentTarot(r, base)) continue;
      filtered.add(r);
    }
    filtered.sort(_compareNewestFirst);
    return List<TarotConnectedMemoryRecord>.unmodifiable(
      _dedupeByTypeAndId(filtered),
    );
  }

  static bool _isCurrentTarot(
    TarotConnectedMemoryRecord r,
    TarotNarrativeRequest base,
  ) {
    if (r.sourceType != TarotConnectedMemorySourceType.tarot) return false;
    final id = r.sourceId.trim();
    if (id == base.readingId) return true;
    if (id == base.sessionId) return true;
    return false;
  }

  static bool _withinLookback(DateTime occurredAt, DateTime nowUtc) {
    final occurredUtc = occurredAt.toUtc();
    if (occurredUtc.compareTo(nowUtc) > 0) return false;
    return nowUtc.difference(occurredUtc) <=
        TarotHistoricalEligibility.lookback;
  }

  static int _compareNewestFirst(
    TarotConnectedMemoryRecord a,
    TarotConnectedMemoryRecord b,
  ) {
    final byTime = b.occurredAt.toUtc().compareTo(a.occurredAt.toUtc());
    if (byTime != 0) return byTime;
    final byType = a.sourceType.name.compareTo(b.sourceType.name);
    if (byType != 0) return byType;
    return a.sourceId.compareTo(b.sourceId);
  }

  static List<TarotConnectedMemoryRecord> _dedupeByTypeAndId(
    List<TarotConnectedMemoryRecord> sorted,
  ) {
    final kept = <TarotConnectedMemoryRecord>[];
    final seen = <String>{};
    for (final r in sorted) {
      final key = '${r.sourceType.name}|${r.sourceId}';
      if (!seen.add(key)) continue;
      kept.add(r);
    }
    return kept;
  }
}

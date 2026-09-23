/// Pure eligibility / lookback / identity dedupe (Phase 4A / 4A.1 / 4E.1 / 4E.1a).
library;

import '../evidence/narrative_request.dart';
import 'tarot_historical_eligibility_order.dart';
import 'tarot_historical_models.dart';

abstract final class TarotHistoricalEligibility {
  TarotHistoricalEligibility._();

  static const lookback = Duration(days: 90);

  /// Owner + current-exclusion + time → sort → physical dedupe → scan bound.
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
    filtered.sort(compareHistoricalNewestFirst);
    final deduped = _dedupePhysicalIdentity(filtered);
    final max = bounds.maxPriorReadingsScanned;
    if (max <= 0) return const [];
    final taken = deduped.length <= max ? deduped : deduped.sublist(0, max);
    return List<TarotHistoricalReadingRecord>.unmodifiable(taken);
  }

  /// H7 — direct pairwise seam only (not transitive).
  static bool samePhysicalIdentity(
    TarotHistoricalReadingRecord a,
    TarotHistoricalReadingRecord b,
  ) {
    final aR = a.readingId.trim();
    final bR = b.readingId.trim();
    final aS = a.sessionId?.trim() ?? '';
    final bS = b.sessionId?.trim() ?? '';

    if (aR.isNotEmpty && bR.isNotEmpty && aR == bR) return true;
    if (aS.isNotEmpty && bS.isNotEmpty && aS == bS) return true;
    if (aR.isNotEmpty && bS.isNotEmpty && aR == bS) return true;
    if (bR.isNotEmpty && aS.isNotEmpty && bR == aS) return true;
    return false;
  }

  /// Collapse transitive alias components; keep newest representative only.
  static List<TarotHistoricalReadingRecord> _dedupePhysicalIdentity(
    List<TarotHistoricalReadingRecord> sortedNewestFirst,
  ) {
    final n = sortedNewestFirst.length;
    if (n <= 1) {
      return List<TarotHistoricalReadingRecord>.unmodifiable(sortedNewestFirst);
    }

    final parent = List<int>.generate(n, (i) => i);
    int find(int i) {
      while (parent[i] != i) {
        parent[i] = parent[parent[i]];
        i = parent[i];
      }
      return i;
    }

    void union(int a, int b) {
      final ra = find(a);
      final rb = find(b);
      if (ra == rb) return;
      if (ra < rb) {
        parent[rb] = ra;
      } else {
        parent[ra] = rb;
      }
    }

    final aliasOwner = <String, int>{};
    for (var i = 0; i < n; i++) {
      for (final token in _identityAliases(sortedNewestFirst[i])) {
        final prev = aliasOwner[token];
        if (prev == null) {
          aliasOwner[token] = i;
        } else {
          union(prev, i);
        }
      }
    }

    final kept = <TarotHistoricalReadingRecord>[];
    final seenRoot = <int>{};
    for (var i = 0; i < n; i++) {
      if (seenRoot.add(find(i))) kept.add(sortedNewestFirst[i]);
    }
    return List<TarotHistoricalReadingRecord>.unmodifiable(kept);
  }

  static Iterable<String> _identityAliases(
    TarotHistoricalReadingRecord r,
  ) sync* {
    final rid = r.readingId.trim();
    if (rid.isNotEmpty) yield rid;
    final sid = r.sessionId?.trim() ?? '';
    if (sid.isNotEmpty) yield sid;
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
}

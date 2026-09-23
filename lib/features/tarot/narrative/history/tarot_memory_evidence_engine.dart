/// Pure bounded memory-evidence assembly (Phase 4B).
library;

import '../evidence/narrative_memory_evidence.dart';
import '../evidence/narrative_request.dart';
import 'tarot_connected_memory_eligibility.dart';
import 'tarot_connected_memory_models.dart';
import 'tarot_historical_current_signals.dart';
import 'tarot_historical_models.dart';
import 'tarot_memory_evidence_support.dart';
import 'tarot_memory_relevance.dart';

abstract final class TarotMemoryEvidenceEngine {
  TarotMemoryEvidenceEngine._();

  static const maxMemoryEntries = 4;

  static TarotNarrativeMemoryEvidence build({
    required TarotNarrativeRequest base,
    required TarotHistoricalSnapshot history,
    required DateTime now,
    required int eligiblePriorReadingCount,
  }) {
    final prior = eligiblePriorReadingCount.clamp(
      0,
      base.bounds.maxPriorReadingsScanned,
    );
    final eligible = TarotConnectedMemoryEligibility.eligible(
      records: history.connectedMemories,
      base: base,
      now: now,
    );
    final currentThemes = TarotHistoricalCurrentSignals.currentThemeIds(
      base.question,
    );
    final currentKw = TarotHistoricalCurrentSignals.cardKeywordsFrom(base);
    final nowUtc = now.toUtc();

    final ranked = <_MemCand>[];
    for (final r in eligible) {
      final rel = TarotMemoryRelevance.score(
        record: r,
        question: base.question,
        currentThemes: currentThemes,
        currentCardKeywords: currentKw,
      );
      if (rel < 0.35) continue;
      ranked.add(_MemCand(record: r, relevance: rel, nowUtc: nowUtc));
    }
    ranked.sort(_compare);

    final budget = base.bounds.maxMemoryChars;
    final selected = <MemoryEvidenceEntry>[];
    var used = 0;
    for (final c in ranked) {
      if (selected.length >= maxMemoryEntries) break;
      final content = TarotMemoryEvidenceSupport.buildContent(
        c.record,
        budget - used,
      );
      if (content == null) continue;
      selected.add(
        MemoryEvidenceEntry(
          evidenceRef:
              'mem_${(selected.length + 1).toString().padLeft(2, '0')}',
          kind: MemoryEvidenceKind.memorySummary,
          contentForModel: content,
          sourceType: c.record.sourceType.name,
          sourceId: c.record.sourceId,
          occurredAt: c.record.occurredAt.toUtc(),
          confidence: TarotMemoryEvidenceSupport.clamp01(c.record.confidence),
          epistemic: c.record.epistemic,
        ),
      );
      used += content.length;
    }

    if (selected.isNotEmpty) {
      return TarotNarrativeMemoryEvidence(
        entries: List<MemoryEvidenceEntry>.unmodifiable(selected),
        priorReadingCount: prior,
        recentCardNames: const [],
        recurringThemeLabels: const [],
        included: true,
        omitReason: 'included',
      );
    }
    return TarotNarrativeMemoryEvidence(
      entries: const [],
      priorReadingCount: prior,
      recentCardNames: const [],
      recurringThemeLabels: const [],
      included: false,
      omitReason: _omitReason(prior, eligible.length),
    );
  }

  static String _omitReason(int prior, int eligibleConnected) {
    if (prior == 0 && eligibleConnected == 0) return 'no_history';
    if (eligibleConnected == 0) return 'empty';
    return 'irrelevant';
  }

  static int _compare(_MemCand a, _MemCand b) {
    final byScore = b.rankingScore.compareTo(a.rankingScore);
    if (byScore != 0) return byScore;
    final byTime = b.record.occurredAt.toUtc().compareTo(
      a.record.occurredAt.toUtc(),
    );
    if (byTime != 0) return byTime;
    final byType = a.record.sourceType.name.compareTo(b.record.sourceType.name);
    if (byType != 0) return byType;
    return a.record.sourceId.compareTo(b.record.sourceId);
  }
}

class _MemCand {
  _MemCand({
    required this.record,
    required this.relevance,
    required this.nowUtc,
  });

  final TarotConnectedMemoryRecord record;
  final double relevance;
  final DateTime nowUtc;

  double get rankingScore => TarotMemoryEvidenceSupport.rankingScore(
    relevance: relevance,
    confidence: record.confidence,
    occurredAt: record.occurredAt,
    nowUtc: nowUtc,
  );
}

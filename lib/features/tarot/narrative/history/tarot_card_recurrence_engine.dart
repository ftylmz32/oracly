/// Pure same-card historical recurrence engine (Phase 4A).
library;

import '../evidence/narrative_card_evidence.dart';
import '../evidence/narrative_question_grounding.dart';
import '../evidence/narrative_recurrence_evidence.dart';
import '../evidence/narrative_request.dart';
import 'tarot_card_recurrence_pick.dart';
import 'tarot_card_recurrence_result.dart';
import 'tarot_historical_eligibility.dart';
import 'tarot_historical_models.dart';
import 'tarot_historical_text.dart';
import 'tarot_recurrence_context.dart';

export 'tarot_card_recurrence_result.dart';

abstract final class TarotCardRecurrenceEngine {
  TarotCardRecurrenceEngine._();

  static TarotCardRecurrenceResult build({
    required TarotNarrativeRequest base,
    required TarotHistoricalSnapshot history,
    required String? currentOwnerId,
    required DateTime now,
  }) {
    final eligible = TarotHistoricalEligibility.eligibleTarotReadings(
      readings: history.tarotReadings,
      currentReadingId: base.readingId,
      currentSessionId: base.sessionId,
      currentOwnerId: currentOwnerId,
      now: now,
      bounds: base.bounds,
    );

    final drafts = <_CardDraft>[];
    for (final card in base.cards) {
      final draft = _buildCard(
        current: card,
        eligible: eligible,
        question: base.question,
        currentCards: base.cards,
        maxSamples: base.bounds.maxRecurringOccurrencesListed,
      );
      if (draft != null) drafts.add(draft);
    }

    drafts.sort(_compareDrafts);
    final out = <TarotRecurringCardEvidence>[];
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      out.add(
        TarotRecurringCardEvidence(
          evidenceId: 'rec_card_${(i + 1).toString().padLeft(2, '0')}',
          canonicalCardId: d.canonicalCardId,
          occurrenceCount: d.occurrenceCount,
          occurrences: d.occurrences,
          contextsOverlap: d.contextsOverlap,
          overlapSummaryKey: d.overlapSummaryKey,
        ),
      );
    }
    return TarotCardRecurrenceResult(
      eligiblePriorReadingCount: eligible.length,
      recurringCards: out,
    );
  }

  static _CardDraft? _buildCard({
    required TarotNarrativeCardEvidence current,
    required List<TarotHistoricalReadingRecord> eligible,
    required QuestionGrounding question,
    required List<TarotNarrativeCardEvidence> currentCards,
    required int maxSamples,
  }) {
    final hits =
        <
          ({
            TarotHistoricalReadingRecord record,
            TarotHistoricalCardOccurrence occurrence,
          })
        >[];
    for (final record in eligible) {
      final occ = TarotCardRecurrencePick.pick(record, current.canonicalCardId);
      if (occ == null) continue;
      hits.add((record: record, occurrence: occ));
    }
    if (hits.isEmpty) return null;

    final keys = <String?>[];
    for (final h in hits) {
      final m = TarotRecurrenceContext.evaluate(
        currentQuestion: question,
        currentCards: currentCards,
        historical: h.record,
        matchedOccurrence: h.occurrence,
      );
      if (m.overlaps) keys.add(m.summaryKey);
    }
    final strongest = TarotRecurrenceContext.strongestKey(keys);

    final samples = <RecurringOccurrence>[];
    final sampleCap = maxSamples < 0 ? 0 : maxSamples;
    for (final h in hits) {
      if (samples.length >= sampleCap) break;
      final pk = h.occurrence.positionKey;
      if (pk == null || pk.isEmpty) continue;
      samples.add(
        RecurringOccurrence(
          readingId: h.record.readingId,
          at: h.record.occurredAt.toUtc(),
          spreadId: h.record.spreadId,
          positionKey: pk,
          isReversed: h.occurrence.isReversed,
          orientationKnown: h.occurrence.orientationKnown,
          intentionSummary: TarotHistoricalText.sanitizeIntention(
            h.record.intentionSummary,
          ),
        ),
      );
    }

    return _CardDraft(
      canonicalCardId: current.canonicalCardId,
      currentPositionIndex: current.positionIndex,
      occurrenceCount: hits.length,
      mostRecentAt: hits.first.record.occurredAt.toUtc(),
      occurrences: List<RecurringOccurrence>.unmodifiable(samples),
      contextsOverlap: strongest != null,
      overlapSummaryKey: strongest,
    );
  }

  static int _compareDrafts(_CardDraft a, _CardDraft b) {
    final byCount = b.occurrenceCount.compareTo(a.occurrenceCount);
    if (byCount != 0) return byCount;
    final byRecent = b.mostRecentAt.compareTo(a.mostRecentAt);
    if (byRecent != 0) return byRecent;
    final byPos = a.currentPositionIndex.compareTo(b.currentPositionIndex);
    if (byPos != 0) return byPos;
    return a.canonicalCardId.compareTo(b.canonicalCardId);
  }
}

class _CardDraft {
  const _CardDraft({
    required this.canonicalCardId,
    required this.currentPositionIndex,
    required this.occurrenceCount,
    required this.mostRecentAt,
    required this.occurrences,
    required this.contextsOverlap,
    required this.overlapSummaryKey,
  });

  final String canonicalCardId;
  final int currentPositionIndex;
  final int occurrenceCount;
  final DateTime mostRecentAt;
  final List<RecurringOccurrence> occurrences;
  final bool contextsOverlap;
  final String? overlapSummaryKey;
}

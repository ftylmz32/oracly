/// Session → normalized Tarot historical row (Phase 4C · FACT authority).
library;

import '../../../../core/domain/models/reading.dart';
import '../../domain/models/reading_session.dart';
import '../../reading/reading_question.dart';
import '../evidence/narrative_question_grounding.dart';
import 'tarot_history_card_normalize.dart';
import 'tarot_history_normalize_diagnostics.dart';
import 'tarot_historical_models.dart';
import 'tarot_historical_text.dart';

abstract final class TarotHistorySessionNormalize {
  TarotHistorySessionNormalize._();

  static bool isEligible(ReadingSession session) {
    if (session.status != ReadingSessionStatus.completed) return false;
    return session.completedAt != null || session.drawnCards.isNotEmpty;
  }

  static ReadingModel? pickEnrichment(
    ReadingSession session,
    List<ReadingModel> readings,
  ) {
    final matches = <ReadingModel>[
      for (final r in readings)
        if (r.sessionId == session.id || r.id == session.id) r,
    ];
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return matches.first;
  }

  /// Returns null when owner conflict or spread unresolvable.
  static ({
    TarotHistoricalReadingRecord? record,
    Set<String> linkedReadingIds,
    TarotHistoryNormalizeDiagnostics diag,
  })
  normalize({
    required ReadingSession session,
    required ReadingModel? linked,
    required String? currentOwnerId,
  }) {
    var diag = const TarotHistoryNormalizeDiagnostics();
    final linkedIds = <String>{};
    if (linked != null) linkedIds.add(linked.id);

    if (linked != null &&
        session.userId != null &&
        linked.userId != null &&
        session.userId != linked.userId) {
      return (
        record: null,
        linkedReadingIds: linkedIds,
        diag: const TarotHistoryNormalizeDiagnostics(skippedOwnerMismatch: 1),
      );
    }

    final spread = TarotHistoryCardNormalize.classicalFromSpread(
      session.spread,
    );
    if (spread == null) {
      return (
        record: null,
        linkedReadingIds: linkedIds,
        diag: const TarotHistoryNormalizeDiagnostics(skippedMalformed: 1),
      );
    }

    final ownerId = session.userId ?? linked?.userId;
    if (!_ownerAllowed(currentOwnerId, ownerId)) {
      return (
        record: null,
        linkedReadingIds: linkedIds,
        diag: const TarotHistoryNormalizeDiagnostics(skippedOwnerMismatch: 1),
      );
    }

    final cards = <TarotHistoricalCardOccurrence>[
      for (final drawn in session.drawnCards)
        ?TarotHistoryCardNormalize.fromSessionCard(
          drawn: drawn,
          spread: spread,
        ),
    ];

    final grounded = NarrativeQuestionGrounding.from(
      rawQuestion: session.intention.text,
      topic: session.intention.topic,
    );
    var intention = TarotHistoricalText.sanitizeIntention(
      ReadingQuestion.real(session.intention.text),
    );
    var topicId = _trimOrNull(session.intention.topic);
    var interpretation = TarotHistoryCardNormalize.boundInterpretation(
      session.interpretation,
    );

    if (linked != null) {
      intention ??= TarotHistoricalText.sanitizeIntention(
        ReadingQuestion.real(linked.intention),
      );
      topicId ??= _trimOrNull(linked.readingType);
      interpretation ??= TarotHistoryCardNormalize.boundInterpretation(
        linked.aiSummary,
      );
    }

    final occurred = (session.completedAt ?? session.startedAt).toUtc();
    return (
      record: TarotHistoricalReadingRecord(
        readingId: session.id,
        sessionId: session.id,
        ownerId: ownerId,
        occurredAt: occurred,
        spreadId: spread.spreadId,
        questionKind: grounded.kind,
        topicId: topicId,
        intentionSummary: intention,
        interpretationSummary: interpretation,
        cards: cards,
      ),
      linkedReadingIds: linkedIds,
      diag: diag,
    );
  }

  static bool _ownerAllowed(String? currentOwnerId, String? rowOwner) {
    if (currentOwnerId != null) {
      return rowOwner != null && rowOwner == currentOwnerId;
    }
    return rowOwner == null;
  }

  static String? _trimOrNull(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}

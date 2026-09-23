/// Deterministic newest-first ordering for historical eligibility (H19).
library;

import 'tarot_historical_models.dart';

/// occurredAt DESC → readingId ASC → sessionId ASC → canonical payload ASC.
int compareHistoricalNewestFirst(
  TarotHistoricalReadingRecord a,
  TarotHistoricalReadingRecord b,
) {
  final byTime = b.occurredAt.toUtc().compareTo(a.occurredAt.toUtc());
  if (byTime != 0) return byTime;
  final byReading = a.readingId.compareTo(b.readingId);
  if (byReading != 0) return byReading;
  final aS = a.sessionId?.trim() ?? '';
  final bS = b.sessionId?.trim() ?? '';
  final bySession = aS.compareTo(bS);
  if (bySession != 0) return bySession;
  return _canonicalTieKey(a).compareTo(_canonicalTieKey(b));
}

/// Internal ordering only — no ownerId, hashCode, or clock.
String _canonicalTieKey(TarotHistoricalReadingRecord r) {
  const u = '\u001f';
  final cards = r.cards
      .map(
        (c) =>
            '${c.canonicalCardId}$u${c.positionIndex}$u${c.positionKey ?? ''}'
            '$u${c.orientationKnown}$u${c.isReversed}',
      )
      .join('\u001e');
  return '${r.spreadId.trim()}$u'
      '${r.questionKind?.name ?? ''}$u'
      '${r.topicId?.trim() ?? ''}$u'
      '${r.intentionSummary?.trim() ?? ''}$u'
      '${r.interpretationSummary?.trim() ?? ''}$u'
      '$cards';
}

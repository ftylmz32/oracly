/// Dream Phase 4A — prior-Dream observations the current dream also holds.
///
/// Counted from the current owner's saved records on every request; never
/// persisted, cached or inferred from prose.
library;

import 'package:flutter/foundation.dart';

enum DreamHistoryEvidenceKind { symbol, location, relationship, emotion, entry }

/// One distinct prior Dream is [seenBefore]; two or more are [recurring].
/// Nothing else counts as a recurrence.
enum DreamRecurrenceLevel {
  seenBefore('seen_before'),
  recurring('recurring');

  const DreamRecurrenceLevel(this.wire);

  final String wire;

  static DreamRecurrenceLevel of(int priorDreamCount) =>
      priorDreamCount >= 2 ? recurring : seenBefore;
}

@immutable
final class DreamHistoryEvidence {
  const DreamHistoryEvidence({
    required this.kind,
    required this.canonicalKey,
    required this.displayLabel,
    required this.priorDreamCount,
    required this.priorDreamIds,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  final DreamHistoryEvidenceKind kind;
  final String canonicalKey;

  /// Label in the operation language, taken from the current dream.
  final String displayLabel;

  /// Exact number of distinct scanned prior Dreams holding [canonicalKey].
  final int priorDreamCount;

  /// Newest first, capped at `DreamHistoryBuilder.maxPriorIds`.
  final List<String> priorDreamIds;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  DreamRecurrenceLevel get level => DreamRecurrenceLevel.of(priorDreamCount);

  int get totalWithCurrent => priorDreamCount + 1;

  /// Provider wire form: no ids, no dates, no prose.
  Map<String, Object> toPayload() => {
        'kind': kind.name,
        'key': canonicalKey,
        'label': displayLabel,
        'level': level.wire,
        'priorCount': priorDreamCount,
      };
}

@immutable
final class DreamHistoryContext {
  const DreamHistoryContext(this.evidence);

  static const empty = DreamHistoryContext([]);

  /// Strongest first, at most `DreamHistoryBuilder.maxEvidence`.
  final List<DreamHistoryEvidence> evidence;

  bool get isEmpty => evidence.isEmpty;

  List<Map<String, Object>> toPayload() =>
      [for (final e in evidence) e.toPayload()];
}

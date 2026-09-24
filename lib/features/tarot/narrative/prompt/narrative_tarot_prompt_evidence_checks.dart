/// Phase 6C.1 — relationship / recurrence / memory checks.
library;

import '../evidence/narrative_request.dart';

abstract final class NarrativeTarotPromptEvidenceChecks {
  NarrativeTarotPromptEvidenceChecks._();

  static void relationships(TarotNarrativeRequest request) {
    final bounds = request.bounds;
    if (request.relationships.length > bounds.maxRelationships) {
      throw ArgumentError(
        'relationships ${request.relationships.length} > '
        '${bounds.maxRelationships}',
      );
    }
    final byPos = {for (final c in request.cards) c.positionKey: c};
    for (final r in request.relationships) {
      if (r.leftCardId == r.rightCardId ||
          r.leftPositionKey == r.rightPositionKey) {
        throw ArgumentError('relationship self-pair forbidden');
      }
      final left = byPos[r.leftPositionKey];
      final right = byPos[r.rightPositionKey];
      if (left == null || right == null) {
        throw ArgumentError('relationship position missing from cards');
      }
      if (left.canonicalCardId != r.leftCardId ||
          right.canonicalCardId != r.rightCardId) {
        throw ArgumentError('relationship card/position correspondence failed');
      }
    }
  }

  static void recurrenceAndMemory(TarotNarrativeRequest request) {
    final bounds = request.bounds;
    final cardIds = {for (final c in request.cards) c.canonicalCardId};
    if (request.recurringThemes.length > bounds.maxThemeLabels) {
      throw ArgumentError(
        'themes ${request.recurringThemes.length} > '
        '${bounds.maxThemeLabels}',
      );
    }
    for (final rc in request.recurringCards) {
      if (!cardIds.contains(rc.canonicalCardId)) {
        throw ArgumentError(
          'recurring card ${rc.canonicalCardId} not in current cards',
        );
      }
      if (rc.occurrences.length > bounds.maxRecurringOccurrencesListed) {
        throw ArgumentError(
          'occurrences ${rc.occurrences.length} > '
          '${bounds.maxRecurringOccurrencesListed}',
        );
      }
    }
    final mem = request.memory;
    if (!mem.included && mem.entries.isNotEmpty) {
      throw ArgumentError('excluded memory cannot carry entries');
    }
    if (mem.included) {
      var chars = 0;
      for (final e in mem.entries) {
        chars += e.contentForModel.length;
      }
      if (chars > bounds.maxMemoryChars) {
        throw ArgumentError(
          'memory chars $chars > ${bounds.maxMemoryChars}',
        );
      }
    }
  }
}

/// Phase 6C.1/6C.2 — relationship / recurrence / memory checks.
library;

import '../evidence/narrative_request.dart';
import 'narrative_tarot_prompt_memory_theme_checks.dart';
import 'narrative_tarot_prompt_scalars.dart';

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
      NarrativeTarotPromptScalars.requireUnit(
        'relationship.strength',
        r.strength,
      );
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
      NarrativeTarotPromptScalars.requireNonBlank(
        'recurring.canonicalCardId',
        rc.canonicalCardId,
      );
      if (!cardIds.contains(rc.canonicalCardId)) {
        throw ArgumentError(
          'recurring card ${rc.canonicalCardId} not in current cards',
        );
      }
      if (rc.occurrenceCount <= 0) {
        throw ArgumentError('occurrenceCount must be > 0');
      }
      if (rc.occurrenceCount < rc.occurrences.length) {
        throw ArgumentError(
          'occurrenceCount ${rc.occurrenceCount} < listed '
          '${rc.occurrences.length}',
        );
      }
      if (rc.occurrences.length > bounds.maxRecurringOccurrencesListed) {
        throw ArgumentError(
          'occurrences ${rc.occurrences.length} > '
          '${bounds.maxRecurringOccurrencesListed}',
        );
      }
      if (rc.contextsOverlap) {
        final key = rc.overlapSummaryKey?.trim();
        if (key == null || key.isEmpty) {
          throw ArgumentError(
            'contextsOverlap true requires overlapSummaryKey',
          );
        }
      } else if (rc.overlapSummaryKey != null) {
        throw ArgumentError(
          'contextsOverlap false requires null overlapSummaryKey',
        );
      }
      for (final o in rc.occurrences) {
        NarrativeTarotPromptScalars.requireNonBlank(
          'occurrence.spreadId',
          o.spreadId,
        );
        NarrativeTarotPromptScalars.requireNonBlank(
          'occurrence.positionKey',
          o.positionKey,
        );
      }
    }
    NarrativeTarotPromptMemoryThemeChecks.themes(request, cardIds);
    NarrativeTarotPromptMemoryThemeChecks.memory(request);
  }
}

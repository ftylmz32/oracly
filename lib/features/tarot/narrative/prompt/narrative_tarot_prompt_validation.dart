/// Phase 6C — closed-world + bounds validation before serialization.
library;

import '../evidence/narrative_request.dart';

abstract final class NarrativeTarotPromptValidation {
  NarrativeTarotPromptValidation._();

  static void validate(TarotNarrativeRequest request) {
    final spread = request.spread;
    if (request.cards.length != spread.cardCount) {
      throw ArgumentError(
        'card count ${request.cards.length} != spread ${spread.cardCount}',
      );
    }

    final byKey = {for (final p in spread.positions) p.positionKey: p};
    final byIndex = {for (final p in spread.positions) p.index: p};
    final seenKeys = <String>{};
    final cardIds = <String>{};

    for (final c in request.cards) {
      if (!seenKeys.add(c.positionKey)) {
        throw ArgumentError('duplicate card position ${c.positionKey}');
      }
      final pos = byKey[c.positionKey];
      if (pos == null) {
        throw ArgumentError('unknown position ${c.positionKey}');
      }
      if (pos.index != c.positionIndex) {
        throw ArgumentError(
          'position index mismatch ${c.positionKey}: '
          '${c.positionIndex} vs ${pos.index}',
        );
      }
      if (byIndex[c.positionIndex]?.positionKey != c.positionKey) {
        throw ArgumentError('index/key mismatch for ${c.positionKey}');
      }
      cardIds.add(c.canonicalCardId);
    }

    final bounds = request.bounds;
    if (request.relationships.length > bounds.maxRelationships) {
      throw ArgumentError(
        'relationships ${request.relationships.length} > '
        '${bounds.maxRelationships}',
      );
    }
    for (final r in request.relationships) {
      if (!cardIds.contains(r.leftCardId) || !cardIds.contains(r.rightCardId)) {
        throw ArgumentError('relationship endpoint not in cards');
      }
      if (!byKey.containsKey(r.leftPositionKey) ||
          !byKey.containsKey(r.rightPositionKey)) {
        throw ArgumentError('relationship position missing from spread');
      }
    }

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

    if (request.memory.included) {
      var chars = 0;
      for (final e in request.memory.entries) {
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

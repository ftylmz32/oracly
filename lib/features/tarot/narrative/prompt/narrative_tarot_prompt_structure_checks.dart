/// Phase 6C.1/6C.2 — spread / card / question structural checks.
library;

import '../../reading/reading_question.dart';
import '../evidence/narrative_request.dart';
import 'narrative_tarot_prompt_scalars.dart';

abstract final class NarrativeTarotPromptStructureChecks {
  NarrativeTarotPromptStructureChecks._();

  static void question(TarotNarrativeRequest request) {
    final q = request.question;
    final raw = q.rawText?.trim();
    if (q.hasRealQuestion) {
      if (raw == null || raw.isEmpty) {
        throw ArgumentError('hasRealQuestion true requires non-empty rawText');
      }
      if (raw.length > ReadingQuestion.maxLength) {
        throw ArgumentError(
          'question length ${raw.length} > ${ReadingQuestion.maxLength}',
        );
      }
    } else if (q.rawText != null) {
      throw ArgumentError('hasRealQuestion false requires rawText null');
    }
  }

  static void spread(TarotNarrativeRequest request) {
    final spread = request.spread;
    if (spread.cardCount <= 0) {
      throw ArgumentError('spread.cardCount must be > 0');
    }
    if (spread.positions.length != spread.cardCount) {
      throw ArgumentError(
        'positions ${spread.positions.length} != cardCount '
        '${spread.cardCount}',
      );
    }
    final keys = <String>{};
    final indices = <int>{};
    for (final p in spread.positions) {
      if (!keys.add(p.positionKey)) {
        throw ArgumentError('duplicate position key ${p.positionKey}');
      }
      if (p.index < 0 || p.index >= spread.cardCount) {
        throw ArgumentError('position index out of range ${p.index}');
      }
      if (!indices.add(p.index)) {
        throw ArgumentError('duplicate position index ${p.index}');
      }
    }
    final expected = {for (var i = 0; i < spread.cardCount; i++) i};
    if (indices.length != expected.length || !indices.containsAll(expected)) {
      throw ArgumentError('position indices must be 0..cardCount-1 exact');
    }

    final order = spread.interpretationOrder;
    if (order.length != spread.cardCount) {
      throw ArgumentError(
        'interpretationOrder length ${order.length} != ${spread.cardCount}',
      );
    }
    final orderSet = <int>{};
    for (final i in order) {
      if (!orderSet.add(i)) {
        throw ArgumentError('duplicate interpretationOrder index $i');
      }
      if (i < 0 || i >= spread.cardCount) {
        throw ArgumentError('interpretationOrder out of range $i');
      }
    }
    if (!orderSet.containsAll(expected)) {
      throw ArgumentError('interpretationOrder must be exact permutation');
    }
  }

  static void cards(TarotNarrativeRequest request) {
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
      NarrativeTarotPromptScalars.requireNonBlank(
        'canonicalCardId',
        c.canonicalCardId,
      );
      NarrativeTarotPromptScalars.requireNonBlank('positionKey', c.positionKey);
      NarrativeTarotPromptScalars.requireNonBlank('displayName', c.displayName);
      if (!seenKeys.add(c.positionKey)) {
        throw ArgumentError('duplicate card position ${c.positionKey}');
      }
      if (!cardIds.add(c.canonicalCardId)) {
        throw ArgumentError('duplicate canonicalCardId ${c.canonicalCardId}');
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
    }
  }
}

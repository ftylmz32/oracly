/// Card / position / spread helpers for Phase 4C Tarot history adapters.
library;

import '../../deck/oracly_tarot_bridge.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/models/tarot_spread.dart';
import '../evidence/narrative_classical_spread_catalog.dart';
import '../evidence/narrative_request.dart';
import '../evidence/narrative_spread_semantics.dart';
import 'tarot_historical_models.dart';
import 'tarot_historical_text.dart';

abstract final class TarotHistoryCardNormalize {
  TarotHistoryCardNormalize._();

  static SpreadSemanticDefinition? classicalFromSpread(TarotSpreadType type) {
    try {
      return ClassicalSpreadSemantics.byLegacyTypeName(type.name);
    } catch (_) {
      return null;
    }
  }

  static SpreadSemanticDefinition? classicalFromTitle(String title) {
    final type = TarotSpreadType.fromTitle(title);
    if (type == null) return null;
    return classicalFromSpread(type);
  }

  static int? validIndex(SpreadSemanticDefinition spread, int? index) {
    if (index == null) return null;
    if (index < 0 || index >= spread.cardCount) return null;
    return index;
  }

  static String? resolvePositionKey({
    required SpreadSemanticDefinition spread,
    required int? positionIndex,
    String? storedKey,
  }) {
    final idx = validIndex(spread, positionIndex);
    final key = storedKey?.trim();
    if (key != null && key.isNotEmpty) {
      for (final pos in spread.positions) {
        if (pos.positionKey == key && idx != null && pos.index == idx) {
          return key;
        }
      }
    }
    if (idx == null) return null;
    for (final pos in spread.positions) {
      if (pos.index == idx) return pos.positionKey;
    }
    return null;
  }

  static TarotHistoricalCardOccurrence? fromSessionCard({
    required TarotDrawnCard drawn,
    required SpreadSemanticDefinition spread,
  }) {
    final bridged = OraclyTarotBridge.byRitualId(drawn.card.id);
    if (bridged == null) return null;
    final idx = validIndex(spread, drawn.positionIndex);
    return TarotHistoricalCardOccurrence(
      canonicalCardId: bridged.id,
      isReversed: drawn.isReversed,
      orientationKnown: true,
      positionIndex: idx,
      positionKey: resolvePositionKey(
        spread: spread,
        positionIndex: idx,
        storedKey: drawn.positionKey,
      ),
    );
  }

  static String? boundInterpretation(String? raw) =>
      TarotHistoricalText.sanitizeIntention(
        raw,
        maxChars: RequestBounds.defaults.maxMemoryChars,
      );

  static String collapseSummary(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsed;
  }
}

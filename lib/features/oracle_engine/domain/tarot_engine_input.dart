/// OR-1140 — Tarot engine input payload.
library;

import '../core/oracle_engine_type.dart';
import '../models/tarot_reading.dart';

class TarotEngineInput {
  const TarotEngineInput({
    required this.spreadType,
    required this.cardIds,
    this.intention,
    this.reversedIndices = const {},
    this.deckId = 'rider-waite',
  });

  final TarotSpreadType spreadType;
  final List<int> cardIds;
  final String? intention;
  final Set<int> reversedIndices;
  final String deckId;

  TarotReading toReading({
    required String id,
    required List<TarotCardDraw> cards,
    required DateTime createdAt,
  }) {
    return TarotReading(
      id: id,
      spreadType: spreadType,
      cards: cards,
      createdAt: createdAt,
      intention: intention,
      deckId: deckId,
    );
  }
}

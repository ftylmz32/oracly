/// Rebuilds [TarotDrawnCard] list from persisted snapshots — never re-rolls.
library;

import '../../../../core/domain/models/reading.dart';
import '../../domain/models/reading_session.dart';
import '../../models/tarot_card.dart';
import '../../services/deck_service.dart';
import '../widgets/reading_history/reading_history_data.dart';

abstract final class SavedReadingDrawnCards {
  SavedReadingDrawnCards._();

  static List<TarotDrawnCard> fromSnapshots(List<ReadingCardSnapshot> cards) {
    if (cards.isEmpty) return const [];
    final byId = {
      for (final card in const DeckService().createDeck()) card.id: card,
    };
    return [
      for (final snap in cards)
        TarotDrawnCard(
          card: byId[snap.cardId] ??
              minimal(
                id: snap.cardId,
                name: snap.cardName,
                image: snap.cardImageAsset,
              ),
          positionIndex: snap.positionIndex,
          isReversed: snap.isReversed,
          positionLabel: snap.positionLabel,
        ),
    ];
  }

  static List<TarotDrawnCard> fromEntry(ReadingHistoryEntry entry) {
    if (entry.cardImageAsset.trim().isEmpty) return const [];
    return [
      TarotDrawnCard(
        card: minimal(
          id: entry.cardIndex,
          name: entry.cardName,
          image: entry.cardImageAsset,
        ),
        positionIndex: 0,
        isReversed: entry.isReversed,
      ),
    ];
  }

  static TarotCard minimal({
    required int id,
    required String name,
    required String image,
  }) {
    return TarotCard(
      id: id,
      name: name,
      image: image,
      arcana: TarotArcana.major,
      suit: TarotSuit.none,
      number: 0,
      summary: '',
      meaning: '',
      reversedMeaning: '',
      keywords: const [],
    );
  }
}
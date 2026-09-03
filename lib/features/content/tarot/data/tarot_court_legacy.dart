/// Backward-compatible court-card content lookup for persisted readings.
library;

import '../../../../core/domain/models/reading.dart';
import '../models/tarot_card_content.dart';
import 'tarot_content_catalogue.dart';

abstract final class TarotCourtLegacy {
  TarotCourtLegacy._();

  static const _minorStart = 22;
  static const _cardsPerSuit = 14;

  static int minorRank(int cardId) {
    if (cardId < _minorStart || cardId > 77) return -1;
    return (cardId - _minorStart) % _cardsPerSuit + 1;
  }

  static bool isLegacyCourtAsset(int cardId, String? imageAsset) {
    final path = imageAsset ?? '';
    if (path.isEmpty) return false;
    final rank = minorRank(cardId);
    if (rank == 13) return path.contains('13_king');
    if (rank == 14) return path.contains('14_queen');
    return false;
  }

  static TarotCardContent contentFor({
    required int cardId,
    String? imageAsset,
  }) {
    final rank = minorRank(cardId);
    final path = imageAsset ?? '';
    if (rank == 13 && path.contains('13_king')) {
      return TarotContentCatalogue.byId(cardId + 1);
    }
    if (rank == 14 && path.contains('14_queen')) {
      return TarotContentCatalogue.byId(cardId - 1);
    }
    return TarotContentCatalogue.byId(cardId);
  }

  static TarotCardContent contentForSnapshot(ReadingCardSnapshot card) =>
      contentFor(cardId: card.cardId, imageAsset: card.cardImageAsset);
}

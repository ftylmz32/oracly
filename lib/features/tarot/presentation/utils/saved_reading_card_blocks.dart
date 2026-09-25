/// Snapshot fallback card prose for saved readings (Phase 7F).
library;

import '../../../../core/domain/models/reading.dart';
import '../../../content/tarot/data/tarot_content_catalogue.dart';
import '../../copy/tarot_l10n.dart';
import '../../copy/tarot_polish_copy.dart';

abstract final class SavedReadingCardBlocks {
  SavedReadingCardBlocks._();

  static String cardsBody(List<ReadingCardSnapshot> cards) {
    if (cards.isEmpty) return '';
    return [for (final card in cards) snapshotBlock(card)].join('\n\n');
  }

  static String snapshotBlock(ReadingCardSnapshot card) {
    final orientation = TarotL10n.orientation(reversed: card.isReversed);
    final pos = card.positionLabel ?? TarotPolishCopy.cardField;
    if (card.cardId <= 0) {
      return '${TarotPolishCopy.cardField}: ${card.cardName} ($orientation)';
    }
    final content = TarotContentCatalogue.forPersistedCard(
      cardId: card.cardId,
      imageAsset: card.cardImageAsset,
    );
    final meaning =
        card.isReversed ? content.reversedMeaning : content.uprightMeaning;
    return '${TarotPolishCopy.cardField}: ${card.cardName}\n'
        '${TarotPolishCopy.orientationLabel}: $orientation\n'
        '${TarotPolishCopy.coreMeaning}: $meaning\n'
        '${TarotPolishCopy.positionMeaning}: $pos';
  }
}

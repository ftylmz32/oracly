/// Spread synthesis — cards connected from what is on the table.
library;

import '../../../core/reading/human_reader.dart';
import '../../tarot/domain/models/tarot_spread.dart';
import '../../tarot/interpretation/models/reading_context.dart';
import 'reflective_card_copy.dart';
import 'reflective_card_relation.dart';

abstract final class ReflectiveSpreadCopy {
  ReflectiveSpreadCopy._();

  static String connect(ReadingContext ctx) {
    final cards = ctx.cards;
    if (cards.isEmpty) return '';
    if (ctx.spreadType == TarotSpreadType.single || cards.length == 1) {
      return _single(cards.first, ctx.userQuestion);
    }
    if (ctx.spreadType == TarotSpreadType.threeCard && cards.length >= 3) {
      return _three(cards, ctx.userQuestion);
    }
    return _many(cards, ctx.spreadLabel, ctx.userQuestion);
  }

  static String _single(ReadingCardContext card, String? asked) {
    final name = ReflectiveCardCopy.named(card);
    return HumanReader.write(
      HumanReaderNotice(
        seed: card.cardId * 13,
        seen: '$name (${card.orientationLabel})',
        meaning: ReflectiveCardCopy.clause(card.effectiveMeaning),
        lifeThread: asked?.trim() ?? '',
        vessel: HumanReader.vesselSpread(),
      ),
    );
  }

  static String _three(List<ReadingCardContext> cards, String? asked) {
    final past = _slot(cards, 'past', 0);
    final now = _slot(cards, 'present', 1);
    final near = _slot(cards, 'direction', 2);
    return HumanReader.write(
      HumanReaderNotice(
        seed: past.cardId + now.cardId * 5,
        seen: ReflectiveCardCopy.named(past),
        companion: ReflectiveCardCopy.named(now),
        meaning: '${ReflectiveCardRelation.pair(past, now)} '
            'Olası yön kartı ${ReflectiveCardCopy.named(near)} '
            '(${near.orientationLabel}) izlenebilecek bir eğilim olarak duruyor: '
            '${ReflectiveCardCopy.clause(near.effectiveMeaning)}',
        lifeThread: asked?.trim() ?? '',
        vessel: HumanReader.vesselSpread(),
      ),
    );
  }

  static ReadingCardContext _slot(
    List<ReadingCardContext> cards,
    String key,
    int fallback,
  ) {
    for (final card in cards) {
      if (card.positionKey == key) return card;
    }
    return cards[fallback];
  }

  static String _many(
    List<ReadingCardContext> cards,
    String spread,
    String? asked,
  ) {
    final primary = cards.first;
    final second = cards.length > 1 ? cards[1] : null;
    final relation = second == null
        ? ReflectiveCardCopy.clause(primary.effectiveMeaning)
        : ReflectiveCardRelation.pair(primary, second);
    return HumanReader.write(
      HumanReaderNotice(
        seed: primary.cardId * 11,
        seen: ReflectiveCardCopy.named(primary),
        meaning: '$spread açılımı ${ReflectiveCardCopy.named(primary)} '
            'etrafında toplanıyor. $relation',
        lifeThread: asked?.trim() ?? '',
        vessel: HumanReader.vesselSpread(),
      ),
    );
  }
}

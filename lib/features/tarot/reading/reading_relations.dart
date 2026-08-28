/// How two drawn cards change each other — never two definitions stacked.
library;

import '../../insights/services/reflective_card_relation.dart';
import '../copy/tarot_l10n.dart';
import '../interpretation/models/reading_context.dart';
import 'reading_hedge.dart';
import 'reading_words.dart';

abstract final class ReadingRelations {
  ReadingRelations._();

  static String after(ReadingCardContext prev, ReadingCardContext next) {
    return '${TarotL10n.fill('tarot.rel.after', {
      'b': ReadingWords.named(next),
      'a': ReadingWords.named(prev),
      'hedge': ReadingHedge.of(prev.cardId + next.cardId * 3),
      'prev': prev.positionLabel,
      'next': next.positionLabel,
    })} ${ReflectiveCardRelation.pair(prev, next)}';
  }

  static String shift(ReadingCardContext prev, ReadingCardContext next) {
    return TarotL10n.fill('tarot.rel.shift', {
      'from': ReadingWords.clause(prev.effectiveMeaning),
      'to': ReadingWords.clause(next.effectiveMeaning),
      'pos': next.positionLabel,
      'hedge': ReadingHedge.of(next.cardId * 11),
    });
  }
}

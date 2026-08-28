/// Heavy and light cards — context, never fear or empty hope.
library;

import '../copy/tarot_l10n.dart';
import '../interpretation/models/reading_context.dart';

abstract final class ReadingCharge {
  ReadingCharge._();

  static String of(ReadingCardContext card) {
    final key = _key(card);
    if (key == null) return '';
    return TarotL10n.fill(key);
  }

  static String? _key(ReadingCardContext card) {
    final slot = '${card.positionKey} ${card.positionLabel}'.toLowerCase();
    final obstacle = _has(slot, [
      'obstacle',
      'engel',
      'challenge',
      'zorluk',
      'препят',
    ]);
    final direction = _has(slot, [
      'direction',
      'yön',
      'future',
      'olası',
      'outcome',
      'путь',
      'итог',
      'gelecek',
    ]);
    final name = card.cardName.toLowerCase();
    if (card.cardId == 16 || _has(name, ['tower', 'kule'])) {
      if (obstacle) return 'tarot.charge.tower.obstacle';
      if (direction) return 'tarot.charge.tower.direction';
      return 'tarot.charge.tower.here';
    }
    if (card.cardId == 13 || _has(name, ['death', 'ölüm'])) {
      return 'tarot.charge.death';
    }
    if (card.cardId == 15 || _has(name, ['devil', 'şeytan'])) {
      return 'tarot.charge.devil';
    }
    if (card.cardId == 17 || _has(name, ['star', 'yıldız'])) {
      return 'tarot.charge.star';
    }
    if (card.cardId == 19 || _has(name, ['sun', 'güneş'])) {
      return 'tarot.charge.sun';
    }
    if (_has(name, ['ten of swords', '10 of swords', 'kılıçların onu', 'десятка мечей'])) {
      return 'tarot.charge.swords10';
    }
    if (_has(name, ['five of cups', '5 of cups', 'kupaların beşi', 'пятёрка кубков'])) {
      return 'tarot.charge.cups5';
    }
    return null;
  }

  static bool _has(String hay, List<String> needles) =>
      needles.any(hay.contains);
}

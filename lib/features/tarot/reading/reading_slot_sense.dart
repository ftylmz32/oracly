/// How a card sits in its spread slot.
library;

import '../copy/tarot_l10n.dart';
import '../interpretation/models/reading_context.dart';

abstract final class ReadingSlotSense {
  ReadingSlotSense._();

  static String of(ReadingCardContext card) {
    final key = card.positionKey.toLowerCase();
    final label = card.positionLabel.toLowerCase();
    if (_is(key, label, ['past', 'geçmiş', 'прошл'])) {
      return TarotL10n.fill('tarot.read.slot.past');
    }
    if (_is(key, label, ['present', 'şimdi', 'current', 'situation', 'sign', 'сейчас'])) {
      return TarotL10n.fill('tarot.read.slot.present');
    }
    if (_is(key, label, ['obstacle', 'challenge', 'engel', 'zorluk', 'трудно', 'препят'])) {
      return TarotL10n.fill('tarot.read.slot.obstacle');
    }
    if (_is(key, label, ['hidden', 'gizli', 'скрыт'])) {
      return TarotL10n.fill('tarot.read.slot.hidden');
    }
    if (_is(key, label, ['strength', 'help', 'güç', 'yardım', 'сил', 'помог'])) {
      return TarotL10n.fill('tarot.read.slot.strength');
    }
    if (_is(key, label, ['avoid', 'kaçın', 'избеж'])) {
      return TarotL10n.fill('tarot.read.slot.avoid');
    }
    if (_is(key, label, ['question', 'soru', 'вопрос'])) {
      return TarotL10n.fill('tarot.read.slot.question');
    }
    if (_is(key, label, ['direction', 'yön', 'future', 'olası', 'outcome', 'путь', 'итог'])) {
      return TarotL10n.fill('tarot.read.slot.direction');
    }
    return TarotL10n.fill('tarot.read.slot.fallback', {'pos': card.positionLabel});
  }

  static bool _is(String key, String label, List<String> needles) {
    for (final n in needles) {
      if (key.contains(n) || label.contains(n)) return true;
    }
    return false;
  }
}

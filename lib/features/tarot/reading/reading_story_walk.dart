/// Walk / frame helpers for ReadingStory.compose.
library;

import '../copy/tarot_l10n.dart';
import '../interpretation/models/reading_context.dart';
import 'reading_ask.dart';
import 'reading_charge.dart';
import 'reading_hedge.dart';
import 'reading_slot_sense.dart';
import 'reading_words.dart';

abstract final class ReadingStoryWalk {
  ReadingStoryWalk._();

  static String askedFrame(String asked, int count) {
    final key = count <= 3
        ? 'tarot.read.compose.asked'
        : 'tarot.read.compose.asked.wide';
    final frame = TarotL10n.fill(key, {'asked': asked});
    final lead = TarotL10n.fill(ReadingAsk.leadKey(asked));
    return '$frame $lead';
  }

  static String directionMarker() {
    final slot = TarotL10n.fill('tarot.read.slot.direction').toLowerCase();
    if (slot.contains('eğilim')) return 'eğilim';
    if (slot.contains('trend')) return 'trend';
    return 'тенденция';
  }

  static String walk(
    ReadingCardContext card,
    ReadingCardContext? prev,
    int seed, {
    required bool fullMeaning,
  }) {
    final hedge = ReadingHedge.of(card.cardId + (prev?.cardId ?? 0) + seed);
    final charge = prev == null ? ReadingCharge.of(card) : '';
    final extra = charge.isEmpty ? '' : ' $charge';
    final head = TarotL10n.fill('tarot.read.walk', {
      'name': ReadingWords.named(card),
      'pos': card.positionLabel,
      'hedge': hedge,
    });
    final sense = ReadingSlotSense.of(card);
    if (!fullMeaning) return '$head $sense$extra';
    return '$head $sense ${ReadingWords.clause(card.effectiveMeaning)}$extra';
  }

  static bool isDirection(ReadingCardContext card) {
    final t = '${card.positionKey} ${card.positionLabel}'.toLowerCase();
    return t.contains('direction') ||
        t.contains('yön') ||
        t.contains('olası') ||
        t.contains('future') ||
        t.contains('путь');
  }
}

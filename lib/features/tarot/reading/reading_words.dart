/// Shared card naming and meaning clips for the reading engine.
library;

import '../../content/tarot/data/tarot_card_gloss.dart';
import '../interpretation/models/reading_context.dart';

abstract final class ReadingWords {
  ReadingWords._();

  static String named(ReadingCardContext card) =>
      TarotCardGloss.named(card.cardName, card.cardId);

  static String clause(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final dot = trimmed.indexOf('.');
    var first = (dot > 0 && dot < trimmed.length - 1)
        ? trimmed.substring(0, dot + 1)
        : (trimmed.endsWith('.') ? trimmed : '$trimmed.');
    if (first.isNotEmpty && first[0].toUpperCase() != first[0]) {
      first = '${first[0].toUpperCase()}${first.substring(1)}';
    }
    return first;
  }
}

/// Per-card tarot prose from the drawn card — never a dictionary entry.
library;

import '../../content/tarot/data/tarot_card_gloss.dart';
import '../../content/tarot/data/tarot_court_legacy.dart';
import '../../content/tarot/models/tarot_card_content.dart';
import '../../tarot/interpretation/models/reading_context.dart';
import '../../tarot/reading/reading_card_beat.dart';

abstract final class ReflectiveCardCopy {
  ReflectiveCardCopy._();

  static String cards(List<ReadingCardContext> cards, {String? question}) {
    return [
      for (var i = 0; i < cards.length; i++)
        block(
          cards[i],
          question: question,
          previous: i > 0 ? cards[i - 1] : null,
          next: i < cards.length - 1 ? cards[i + 1] : null,
        ),
    ].join('\n\n');
  }

  static String block(
    ReadingCardContext card, {
    String? question,
    ReadingCardContext? previous,
    ReadingCardContext? next,
  }) {
    return ReadingCardBeat.write(
      card,
      question: question,
      previous: previous,
      next: next,
    );
  }

  static String named(ReadingCardContext card) =>
      TarotCardGloss.named(card.cardName, card.cardId);

  static String domain(
    ReadingCardContext card,
    String Function(TarotCardContent) pick,
  ) =>
      pick(TarotCourtLegacy.contentFor(
        cardId: card.cardId,
        imageAsset: card.imageAsset,
      ));

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

/// One card in its real slot — identity, orientation, meaning, neighbors.
library;

import '../copy/tarot_l10n.dart';
import '../interpretation/models/reading_context.dart';
import 'reading_charge.dart';
import 'reading_hedge.dart';
import 'reading_question.dart';
import 'reading_relations.dart';
import 'reading_slot_sense.dart';
import 'reading_words.dart';

abstract final class ReadingCardBeat {
  ReadingCardBeat._();

  static String all(ReadingContext ctx) {
    final cards = ctx.cards;
    return [
      for (var i = 0; i < cards.length; i++)
        write(
          cards[i],
          question: ReadingQuestion.real(ctx.userQuestion),
          previous: i > 0 ? cards[i - 1] : null,
          next: i < cards.length - 1 ? cards[i + 1] : null,
        ),
    ].join('\n\n');
  }

  static String write(
    ReadingCardContext card, {
    String? question,
    ReadingCardContext? previous,
    ReadingCardContext? next,
  }) {
    final asked = ReadingQuestion.real(question) ?? '';
    final parts = <String>[
      TarotL10n.fill('tarot.read.beat.head', {
        'name': ReadingWords.named(card),
        'pos': card.positionLabel,
        'ori': card.orientationLabel,
        'hedge': ReadingHedge.of(card.cardId * 17 + card.positionIndex),
      }),
      '${ReadingSlotSense.of(card)} ${ReadingWords.clause(card.effectiveMeaning)}',
      TarotL10n.fill('tarot.read.beat.body'),
    ];
    final charge = ReadingCharge.of(card);
    if (charge.isNotEmpty) parts.add(charge);
    if (card.isReversed) {
      parts.add(TarotL10n.fill('tarot.read.beat.reversed'));
    }
    if (asked.isNotEmpty) {
      parts.add(TarotL10n.fill('tarot.read.beat.asked', {
        'asked': asked,
        'pos': card.positionLabel,
      }));
    }
    if (previous != null) {
      parts.add(ReadingRelations.after(previous, card));
    }
    if (next != null && previous == null) {
      parts.add(TarotL10n.fill('tarot.read.beat.next', {
        'name': ReadingWords.named(next),
      }));
    }
    return parts.join(' ');
  }

  static String insight(ReadingCardContext card) {
    return ReadingWords.clause(card.effectiveMeaning);
  }

  static String detail(
    ReadingCardContext card, {
    String? question,
    ReadingCardContext? previous,
    ReadingCardContext? next,
  }) {
    return clip(
      write(
        card,
        question: question,
        previous: previous,
        next: next,
      ),
    );
  }

  static String clip(String text, {int max = 5}) {
    final sentences = _sentences(text);
    if (sentences.isEmpty) return text.trim();
    if (sentences.length <= max) return sentences.join(' ');
    return sentences.take(max).join(' ');
  }

  static List<String> _sentences(String text) {
    return RegExp(r'[^.!?…]+[.!?…]?')
        .allMatches(text.trim())
        .map((m) => m.group(0)?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

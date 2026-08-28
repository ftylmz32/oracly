/// Intention-specific tarot interpretation — love, career, daily, general.
library;

import '../../tarot/copy/tarot_l10n.dart';
import '../../tarot/deck/oracly_tarot_bridge.dart';
import '../../tarot/interpretation/models/reading_context.dart';
import '../../tarot/reading/reading_question.dart';
import 'reflective_card_copy.dart';
import 'reflective_card_relation.dart';

abstract final class ReflectiveIntentionCopy {
  ReflectiveIntentionCopy._();

  static String love(ReadingContext ctx) {
    final card = ctx.cards.first;
    return _fill(
      'tarot.intent.love',
      'tarot.intent.love.q',
      ctx,
      card,
      meaning: OraclyTarotBridge.love(card.cardId, language: ctx.language),
      related: ctx.cards.length > 1
          ? ' ${ReflectiveCardRelation.pair(card, ctx.cards[1])}'
          : '',
    );
  }

  static String career(ReadingContext ctx) {
    final card = ctx.cards.length > 1 ? ctx.cards[1] : ctx.cards.first;
    return _fill(
      'tarot.intent.career',
      'tarot.intent.career.q',
      ctx,
      card,
      meaning: OraclyTarotBridge.career(card.cardId, language: ctx.language),
    );
  }

  static String daily(ReadingContext ctx) {
    return _fill(
      'tarot.intent.daily',
      'tarot.intent.daily.q',
      ctx,
      ctx.cards.first,
      meaning: ReflectiveCardCopy.clause(ctx.cards.first.effectiveMeaning),
    );
  }

  static String general(ReadingContext ctx) {
    final card = ctx.cards.first;
    return _fill(
      'tarot.intent.general',
      'tarot.intent.general.q',
      ctx,
      card,
      meaning: OraclyTarotBridge.personal(card.cardId, language: ctx.language),
      related: ctx.cards.length > 1
          ? ' ${ReflectiveCardRelation.pair(card, ctx.cards[1])}'
          : '',
    );
  }

  static String _fill(
    String key,
    String qKey,
    ReadingContext ctx,
    ReadingCardContext card, {
    required String meaning,
    String related = '',
  }) {
    final asked = ReadingQuestion.real(ctx.userQuestion) ?? '';
    return TarotL10n.fill(key, {
      'name': ReflectiveCardCopy.named(card),
      'ori': card.orientationLabel,
      'meaning': ReflectiveCardCopy.clause(
        meaning.trim().isEmpty ? card.effectiveMeaning : meaning,
      ),
      'related': related,
      'q': asked.isEmpty ? '' : TarotL10n.fill(qKey, {'asked': asked}),
    });
  }
}

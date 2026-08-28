/// Leave with a direction, a reflection, a question — not a guaranteed future.
library;

import '../copy/tarot_l10n.dart';
import '../interpretation/models/reading_context.dart';
import 'reading_ask.dart';
import 'reading_hedge.dart';
import 'reading_question.dart';
import 'reading_story.dart';
import 'reading_words.dart';

abstract final class ReadingGuidance {
  ReadingGuidance._();

  static String closing(ReadingContext ctx) {
    if (ctx.cards.isEmpty) return '';
    final aim = ctx.cards.last;
    final asked = ReadingQuestion.real(ctx.userQuestion) ?? '';
    final qBit = asked.isNotEmpty
        ? TarotL10n.fill('tarot.guide.close.q', {
            'asked': asked,
            'pos': aim.positionLabel,
          })
        : ' ${ReadingStory.opening(ctx).split('.').first}.';
    return '${TarotL10n.fill('tarot.guide.close', {
      'name': ReadingWords.named(aim),
      'meaning': ReadingWords.clause(aim.effectiveMeaning),
      'hedge': ReadingHedge.of(aim.cardId + 5),
    })} $qBit ${TarotL10n.fill(ReadingAsk.closeKey(asked))}';
  }

  static String practical(ReadingContext ctx) {
    final close = closing(ctx);
    if (ctx.cards.isEmpty) return close;
    final theme = switch (ctx.readingTheme) {
      'love' => TarotL10n.fill('tarot.guide.theme.love'),
      'career' => TarotL10n.fill('tarot.guide.theme.career'),
      'daily' => TarotL10n.fill('tarot.guide.theme.daily'),
      'general' => TarotL10n.fill('tarot.guide.theme.general'),
      _ => TarotL10n.fill('tarot.guide.theme.other'),
    };
    return TarotL10n.fill('tarot.guide.practical', {
      'close': close,
      'theme': theme,
    });
  }

  static String questions(ReadingContext ctx) {
    final asked = ReadingQuestion.real(ctx.userQuestion) ?? '';
    if (ctx.cards.isEmpty) return TarotL10n.fill('tarot.read.need');
    final here = ctx.cards.length > 1 ? ctx.cards[1] : ctx.cards.first;
    final aim = ctx.cards.last;
    if (asked.isNotEmpty) {
      return TarotL10n.fill('tarot.guide.q.asked', {
        'asked': asked,
        'here': here.positionLabel,
        'aim': aim.positionLabel,
        'name': ReadingWords.named(aim),
      });
    }
    return switch (ctx.readingTheme) {
      'love' => TarotL10n.fill('tarot.guide.q.love'),
      'career' => TarotL10n.fill('tarot.guide.q.career'),
      'daily' => TarotL10n.fill('tarot.guide.q.daily'),
      _ => TarotL10n.fill('tarot.guide.q.other'),
    };
  }
}

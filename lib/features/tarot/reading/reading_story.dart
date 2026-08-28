/// Coherent spread story from real cards, slots, and the asked question.
library;

import '../copy/tarot_l10n.dart';
import '../interpretation/models/reading_context.dart';
import 'reading_ask.dart';
import 'reading_charge.dart';
import 'reading_hedge.dart';
import 'reading_length.dart';
import 'reading_question.dart';
import 'reading_relations.dart';
import 'reading_story_walk.dart';
import 'reading_words.dart';

abstract final class ReadingStory {
  ReadingStory._();

  static String opening(ReadingContext ctx) {
    if (ctx.cards.isEmpty) return '';
    final first = ctx.cards.first;
    final asked = ReadingQuestion.real(ctx.userQuestion) ?? '';
    final preface = ctx.journeyHints?.observationalPreface() ?? '';
    final head = preface.isNotEmpty ? '$preface ' : '';
    final lead =
        asked.isEmpty ? '' : '${TarotL10n.fill(ReadingAsk.leadKey(asked))} ';
    final seed = (ctx.shuffleSeed ?? 0) +
        (ctx.journeyHints?.priorReadingCount ?? 0);
    final hedge = ReadingHedge.of(first.cardId + seed);
    return '$head$lead${_variant(ctx, asked, ReadingWords.named(first), hedge, ReadingWords.clause(first.effectiveMeaning))}';
  }

  static int _openingIndex(ReadingContext ctx) {
    return (ctx.journeyHints?.priorReadingCount ?? 0) + (ctx.shuffleSeed ?? 0);
  }

  static String _variant(
    ReadingContext ctx,
    String asked,
    String name,
    String hedge,
    String meaning,
  ) {
    final first = ctx.cards.first;
    final vars = {
      'asked': asked,
      'pos': first.positionLabel,
      'name': name,
      'hedge': hedge,
      'meaning': meaning,
      'thread': _themeThread(ctx),
    };
    final a = asked.isNotEmpty
        ? TarotL10n.fill('tarot.story.asked.a', vars)
        : TarotL10n.fill('tarot.story.open.a', vars);
    final b = asked.isNotEmpty
        ? TarotL10n.fill('tarot.story.asked.b', vars)
        : TarotL10n.fill('tarot.story.open.b', vars);
    final pickB =
        _openingIndex(ctx).isOdd || (ctx.journeyHints?.echoes(a) ?? false);
    return pickB ? b : a;
  }

  static String compose(ReadingContext ctx) {
    final cards = ctx.cards;
    if (cards.isEmpty) return '';
    if (cards.length == 1) {
      return ReadingLength.clip(
        opening(ctx),
        ReadingLength.narrativeMax(1),
      );
    }
    final asked = ReadingQuestion.real(ctx.userQuestion) ?? '';
    final seed = (ctx.shuffleSeed ?? 0) +
        (ctx.journeyHints?.priorReadingCount ?? 0);
    final parts = <String>[
      if (asked.isNotEmpty) ReadingStoryWalk.askedFrame(asked, cards.length),
      ReadingStoryWalk.walk(cards.first, null, seed, fullMeaning: true),
    ];
    for (var i = 1; i < cards.length; i++) {
      parts.add(ReadingRelations.after(cards[i - 1], cards[i]));
      final charge = ReadingCharge.of(cards[i]);
      if (charge.isNotEmpty) parts.add(charge);
      parts.add(
        ReadingStoryWalk.walk(
          cards[i],
          cards[i - 1],
          seed,
          fullMeaning: cards.length <= 3 || i == cards.length - 1,
        ),
      );
      if (ReadingStoryWalk.isDirection(cards[i])) {
        parts.add(ReadingRelations.shift(cards[i - 1], cards[i]));
      }
    }
    if (cards.length >= 5 && asked.isNotEmpty) {
      parts.add(TarotL10n.fill('tarot.read.compose.tension', {'asked': asked}));
    }
    final raw = parts.join(' ');
    final max = ReadingLength.narrativeMax(cards.length);
    final direction = cards.where(ReadingStoryWalk.isDirection).lastOrNull;
    if (direction != null) {
      return ReadingLength.keep(
        raw,
        mustContain: ReadingStoryWalk.directionMarker(),
        also: direction.cardName,
        max: max,
      );
    }
    return ReadingLength.clip(raw, max);
  }

  static String _themeThread(ReadingContext ctx) => switch (ctx.readingTheme) {
        'love' => TarotL10n.fill('tarot.read.theme.love'),
        'career' => TarotL10n.fill('tarot.read.theme.career'),
        'daily' => TarotL10n.fill('tarot.read.theme.daily'),
        'general' => TarotL10n.fill('tarot.read.theme.general'),
        'money' => TarotL10n.fill('tarot.read.theme.money'),
        _ => TarotL10n.fill('tarot.read.theme.other'),
      };
}

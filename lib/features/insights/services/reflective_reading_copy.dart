/// Interpretation-first tarot copy — delegates to the reading engine.
library;

import '../../tarot/interpretation/models/reading_context.dart';
import '../../tarot/reading/reading_card_beat.dart';
import '../../tarot/reading/reading_guidance.dart';
import '../../tarot/reading/reading_story.dart';

abstract final class ReflectiveReadingCopy {
  ReflectiveReadingCopy._();

  static String general(ReadingContext ctx) => theme(ctx);

  static String theme(ReadingContext ctx) => ReadingStory.opening(ctx);

  static String cards(List<ReadingCardContext> cards, {String? question}) {
    return [
      for (var i = 0; i < cards.length; i++)
        ReadingCardBeat.write(
          cards[i],
          question: question,
          previous: i > 0 ? cards[i - 1] : null,
          next: i < cards.length - 1 ? cards[i + 1] : null,
        ),
    ].join('\n\n');
  }

  static String synthesis(ReadingContext ctx) => ReadingStory.compose(ctx);

  static String practical(ReadingContext ctx) =>
      ReadingGuidance.practical(ctx);

  static String conclusion(ReadingContext ctx) => practical(ctx);

  static String questions(ReadingContext ctx) =>
      ReadingGuidance.questions(ctx);
}

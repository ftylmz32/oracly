/// Real tarot reading — question, slots, cards, relations, story, guidance.
library;

import '../../insights/services/reflective_intention_copy.dart';
import '../interpretation/models/interpretation_result.dart';
import '../interpretation/models/reading_context.dart';
import 'reading_card_beat.dart';
import 'reading_guidance.dart';
import 'reading_story.dart';

abstract final class TarotReadingEngine {
  TarotReadingEngine._();

  static String _themeAdvice(ReadingContext context) {
    final theme = context.readingTheme ?? 'general';
    return switch (theme) {
      'love' => ReflectiveIntentionCopy.love(context),
      'career' => ReflectiveIntentionCopy.career(context),
      'daily' => ReflectiveIntentionCopy.daily(context),
      _ => ReadingStory.compose(context).split('.').first.trim(),
    };
  }

  static InterpretationResult run({
    required ReadingContext context,
    required String requestId,
  }) {
    final theme = context.readingTheme ?? 'general';
    return InterpretationResult(
      requestId: requestId,
      sessionId: context.sessionId,
      summary: ReadingStory.opening(context),
      love: theme == 'love' ? ReflectiveIntentionCopy.love(context) : '',
      career: theme == 'career' ? ReflectiveIntentionCopy.career(context) : '',
      money: theme == 'general' || theme == 'money'
          ? ReflectiveIntentionCopy.general(context)
          : '',
      health: ReadingCardBeat.all(context),
      spiritualGuidance:
          theme == 'daily' ? ReflectiveIntentionCopy.daily(context) : '',
      advice: _themeAdvice(context),
      warnings: ReadingGuidance.questions(context),
      luckyEnergy: ReadingStory.compose(context),
      dailyFocus: ReadingGuidance.practical(context),
      closingMessage: ReadingGuidance.closing(context),
      generatedAt: DateTime.now(),
      source: InterpretationSource.local,
      rawText: ReadingCardBeat.all(context),
    );
  }
}

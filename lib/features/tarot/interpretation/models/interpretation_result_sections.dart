/// Locale-aware interpretation section titles.
library;

import '../../copy/tarot_polish_copy.dart';
import 'interpretation_result.dart';

List<InterpretationSection> interpretationSectionsOf(InterpretationResult r) {
  return [
    InterpretationSection(
      key: InterpretationSectionKey.summary,
      title: TarotPolishCopy.themeTitle,
      content: r.summary,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.health,
      title: TarotPolishCopy.cardsTitle,
      content: r.health,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.luckyEnergy,
      title: TarotPolishCopy.synthesisFullTitle,
      content: r.luckyEnergy,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.love,
      title: TarotPolishCopy.loveTitle,
      content: r.love,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.career,
      title: TarotPolishCopy.careerTitle,
      content: r.career,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.money,
      title: TarotPolishCopy.overviewTitle,
      content: r.money,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.spiritualGuidance,
      title: TarotPolishCopy.dailyFalTitle,
      content: r.spiritualGuidance,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.dailyFocus,
      title: TarotPolishCopy.practicalTitle,
      content: r.dailyFocus,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.warnings,
      title: TarotPolishCopy.questionTitle,
      content: r.warnings,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.advice,
      title: TarotPolishCopy.adviceTitle,
      content: r.advice,
    ),
    InterpretationSection(
      key: InterpretationSectionKey.closingMessage,
      title: TarotPolishCopy.closingTitle,
      content: r.closingMessage,
    ),
  ];
}

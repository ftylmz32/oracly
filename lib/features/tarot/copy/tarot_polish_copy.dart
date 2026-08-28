/// TAROT V2 — interpretation-first localized copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_living_voice.dart';

abstract final class TarotPolishCopy {
  TarotPolishCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get startInstruction => _t('tarot.start');
  static String get entryQuestionHint => _t('tarot.entry.question_ph');
  static List<String> get entryQuestionExamples => [
        _t('tarot.entry.ex.0'),
        _t('tarot.entry.ex.1'),
        _t('tarot.entry.ex.2'),
      ];
  static String get startSpreadCta => _t('tarot.entry.cta');
  static String get spreadSingleBlurb => _t('tarot.spread.single.blurb');
  static String get spreadThreeBlurb => _t('tarot.spread.three.blurb');
  static String get spreadFiveBlurb => _t('tarot.spread.five.blurb');
  static String get spreadSevenBlurb => _t('tarot.spread.seven.blurb');
  static String get intentionPlaceholder => _t('tarot.intention_ph');
  static List<String> get intentionExamples => [
        _t('tarot.intention.0'),
        _t('tarot.intention.1'),
        _t('tarot.intention.2'),
      ];
  static String get skipIntention => _t('tarot.skip');
  static String get continueIntention => _t('tarot.continue');
  static String get cutDeck => _t('tarot.cut_deck');
  static String get revealComplete => _t('tarot.reveal.complete');
  static String get drawManual => _t('tarot.draw.manual');
  static String get drawOr => _t('tarot.draw.or');
  static String get drawManualBlurb => _t('tarot.draw.manual_blurb');
  static String get drawOrBlurb => _t('tarot.draw.or_blurb');
  static String get stepIntention => _t('tarot.step.intention');
  static String get stepSelection => _t('tarot.step.selection');
  static String get stepReveal => _t('tarot.step.reveal');
  static String get stepReading => _t('tarot.step.reading');
  static String get storyTitle => _t('tarot.story_title');
  static String get relationsTitle => _t('tarot.relations_title');
  static String get directionTitle => _t('tarot.direction_title');
  static String get orOpen => _t('tarot.or_open');
  static String get themeTitle => _t('tarot.theme_title');
  static String get emotionsTitle => _t('tarot.emotions');
  static String get innerWorldTitle => _t('tarot.inner_world');
  static String get yourMessageTitle => _t('tarot.your_message');
  static String get cardsTitle => _t('tarot.cards_title');
  static String get synthesisTitle => _t('tarot.synthesis');
  static String get synthesisFullTitle => _t('tarot.synthesis_full');
  static String get overviewTitle => _t('tarot.overview');
  static String get dailyFalTitle => _t('tarot.daily_fal');
  static String get adviceTitle => _t('tarot.section.advice');
  static String get closingTitle => _t('tarot.closing');
  static String get keysPrefix => _t('tarot.keys.prefix');
  static String get nearTerm => _t('tarot.near_term');
  static String get loveTitle => _t('tarot.love');
  static String get careerTitle => _t('tarot.career');
  static String get generalTitle => _t('tarot.general');
  static String get dailyTitle => _t('tarot.daily');
  static String get practicalTitle => _t('tarot.practical');
  static String get questionTitle => _t('tarot.question');
  static String get cardField => _t('tarot.card_field');
  static String get orientationLabel => _t('tarot.orientation');
  static String get upright => _t('tarot.upright');
  static String get reversed => _t('tarot.reversed');
  static String get coreMeaning => _t('tarot.core_meaning');
  static String get positionMeaning => _t('tarot.position_meaning');
  static String get interpreting =>
      OrLivingVoice.thinking(surface: OrLivingSurface.tarot);
  static String get interpretFailed => _t('tarot.interpret_failed');
  static String get readingUnavailable => _t('tarot.reading_unavailable');
  static String get retry => _t('tarot.retry');
  static String get askOracleHint => _t('tarot.ask_hint');
  static String get disclaimer => _t('tarot.disclaimer');
  static String get readingTitleLocal => _t('tarot.reading_local');
  static String get readingTitleAi => _t('tarot.reading_ai');
  static String get sourceLocal => _t('tarot.source_local');
  static String get sourceAi => _t('tarot.source_ai');

  static String readingFootnote({required bool fromAi}) {
    final source = fromAi ? sourceAi : sourceLocal;
    return '$source $disclaimer';
  }

  static String selectCards(int count) =>
      _t('tarot.select_n').replaceAll('{n}', '$count');

  static String cardProgress(int current, int total) => '$current / $total';

  static String gemCost(int amount) =>
      _t('tarot.gem_cost').replaceAll('{n}', '$amount');

  static String coreMeaningLine(String theme) =>
      _t('tarot.core_line').replaceAll('{theme}', theme);
}

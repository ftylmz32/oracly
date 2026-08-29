/// RC-012 — Warm, human copy for the first session.
library;

import '../l10n/l10n.dart';

abstract final class FirstSessionCopy {
  FirstSessionCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get homeGreeting => _t('first.home_greeting');
  static String get homeGuestName => _t('first.guest');
  static String get homeSubtitleNew => _t('first.sub_new');
  static String get homeSubtitleReturning => _t('first.sub_return');
  static String get homeCta => _t('first.home_cta');
  static String get soulMateLater => _t('first.soulmate_later');

  static String continuityInvite(String cardName) =>
      _t('first.continuity_invite').replaceAll('{card}', cardName.trim());

  static String get continuityCta => _t('first.continuity_cta');

  static String get intentionTitle => _t('first.intention_title');
  static String get intentionSubtitle => _t('first.intention_sub');
  static String get intentionTitleDefault => _t('first.intention_title_d');
  static String get intentionSubtitleDefault => _t('first.intention_sub_d');
  static String get shuffleMessage => _t('first.shuffle');
  static String get shuffleMessageDefault => _t('first.shuffle_d');
  static String get cardSelectionTitle => _t('first.card_title');
  static String get cardSelectionSubtitle => _t('first.card_sub');
  static String get cardSelectionTitleDefault => _t('first.card_title_d');
  static String get cardSelectionSubtitleDefault => _t('first.card_sub_d');
  static String get revealContinue => _t('first.reveal');
  static String get revealContinueDefault => _t('first.reveal_d');
  static String get introBreath => _t('first.breath');
  static String get introPreparingFirst => _t('first.prep_first');
  static String get introPreparingDefault => _t('first.prep_d');

  static String intentionTitleFor({required bool isFirstSession}) =>
      isFirstSession ? intentionTitle : intentionTitleDefault;

  static String intentionSubtitleFor({required bool isFirstSession}) =>
      isFirstSession ? intentionSubtitle : intentionSubtitleDefault;

  static String shuffleMessageFor({required bool isFirstSession}) =>
      isFirstSession ? shuffleMessage : shuffleMessageDefault;

  static String cardSelectionTitleFor({required bool isFirstSession}) =>
      isFirstSession ? cardSelectionTitle : cardSelectionTitleDefault;

  static String cardSelectionSubtitleFor({required bool isFirstSession}) =>
      isFirstSession ? cardSelectionSubtitle : cardSelectionSubtitleDefault;

  static String revealContinueFor({required bool isFirstSession}) =>
      isFirstSession ? revealContinue : revealContinueDefault;

  static String introPreparingFor({required bool isFirstSession}) =>
      isFirstSession ? introPreparingFirst : introPreparingDefault;
}

/// EPIC-014 — Trust through transparency: shared communication copy.
library;

import '../l10n/l10n.dart';

abstract final class TransparencyCopy {
  TransparencyCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get interpretationFootnote => _t('trust.footnote');
  static String get interpretationBrief => _t('trust.brief');
  static String get conversationCaption => _t('trust.conversation');
  static String get journalPrivacy => _t('trust.journal_privacy');
  static String get journalEmptyPrompt => _t('trust.journal_empty');
  static String get journeyOwnership => _t('trust.journey');
  static String get insightFootnote => _t('trust.insight');
  static String get privacyIntro => _t('trust.privacy_intro');
  static String get aboutBoundary => _t('trust.about_boundary');
  static String get deleteReadingTitle => _t('trust.delete_title');
  static String get deleteReadingBody => _t('trust.delete_body');
  static String get deleteReadingConfirm => _t('trust.delete_confirm');
  static String get deleteReadingCancel => _t('trust.delete_cancel');
  static String get memoryDeleteTitle => _t('trust.memory_title');
  static String get memoryDeleteBody => _t('trust.memory_body');
  static String get memoryDeleteConfirm => _t('trust.delete_confirm');
  static String get memoryDeleteCancel => _t('trust.delete_cancel');
  static String get journalCleared => _t('trust.journal_cleared');
  static String get memoryCleared => _t('trust.memory_cleared');
  static String get chatHistoryCleared => _t('trust.chat_cleared');
  static String get allDataReset => _t('trust.all_reset');
  static String get analyticsTitle => _t('trust.analytics_title');
  static String get analyticsSubtitle => _t('trust.analytics_subtitle');
}

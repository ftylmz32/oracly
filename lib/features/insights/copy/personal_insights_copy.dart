/// SPRINT-004 — Calm, letter-like copy for Personal Insights.
library;

import '../../../core/l10n/l10n.dart';

abstract final class PersonalInsightsCopy {
  PersonalInsightsCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('insights.title');
  static String get salutation => _t('insights.salutation');
  static String get closingNote => _t('insights.closing');
  static String get emptyTitle => _t('insights.empty_title');
  static String get emptyBody => _t('insights.empty_body');
  static String get footnote => _t('trust.insight');
  static String get privacyTitle => _t('insights.privacy');
  static String get hideAction => _t('insights.hide');
  static String get deleteAction => _t('insights.delete');
  static String get regenerateAction => _t('insights.regen');
  static String get exportAction => _t('insights.export');
  static String get hiddenConfirmation => _t('insights.hidden');
  static String get deletedConfirmation => _t('insights.deleted');
  static String get regeneratedConfirmation => _t('insights.regen_ok');
  static String get exportedConfirmation => _t('insights.exported');
  static String get deletePrompt => _t('insights.delete_prompt');
  static String get exportHeader => _t('insights.export_header');
}

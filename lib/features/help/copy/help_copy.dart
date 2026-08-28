/// Help / support copy — calm, metadata-only reports.
library;

import '../../../core/l10n/l10n.dart';
import '../models/support_category.dart';

abstract final class HelpCopy {
  HelpCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('help.title');
  static String get subtitle => _t('help.subtitle');
  static String get report => _t('help.report');
  static String get reportSubtitle => _t('help.report_subtitle');
  static String get contact => _t('help.contact');
  static String get contactSubtitle => _t('help.contact_subtitle');
  static String get privacyNote => _t('help.privacy_note');
  static String get reportTitle => _t('help.report_title');
  static String get reportHint => _t('help.report_hint');
  static String get send => _t('help.send');
  static String get mailOpened => _t('help.mail_opened');
  static String get mailCopied => _t('help.mail_copied');
  static String get diagnosticsTitle => _t('help.diagnostics_title');
  static String get diagnosticsVersion => _t('help.diagnostics_version');
  static String get diagnosticsBuild => _t('help.diagnostics_build');
  static String get diagnosticsCopy => _t('help.diagnostics_copy');
  static String get diagnosticsCopyHint => _t('help.diagnostics_copy_hint');
  static String get diagnosticsCopied => _t('help.diagnostics_copied');
  static String get diagnosticsPrivacy => _t('help.diagnostics_privacy');

  static String category(SupportCategory value) => _t(value.labelKey);
}

/// RC-003 — User-facing resilience copy: errors, loading, empty states.
library;

import '../l10n/l10n.dart';

abstract final class ResilienceCopy {
  ResilienceCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get errorTitle => _t('resilience.error_title');
  static String get retryAction => _t('resilience.retry');
  static String get chatLoading => _t('resilience.chat_loading');
  static String get memoryLoading => _t('resilience.memory_loading');
  static String get historyLoading => _t('resilience.history_loading');
  static String get splashLoading => _t('resilience.splash_loading');
  static String get genericLoading => _t('resilience.generic_loading');
  static String get settingsLoading => _t('resilience.settings_loading');
  static String get achievementsLoading =>
      _t('resilience.achievements_loading');
  static String get profileLoading => _t('resilience.profile_loading');
  static String get genericLoadFailed => _t('resilience.generic_failed');
  static String get offline => _t('resilience.offline');
  static String get temporaryFailure => _t('resilience.temporary');
  static String get invalidInput => _t('resilience.invalid_input');
  static String get analysisUnavailable =>
      _t('resilience.analysis_unavailable');
  static String get historyLoadFailed => _t('resilience.history_failed');
  static String get historyLoadFailedTitle =>
      _t('resilience.history_failed_title');
  static String get slowResponse => _t('resilience.slow');
  static String get aiUnavailable => _t('resilience.ai_unavailable');
  static String get aiConfigMissing => _t('resilience.ai_config');
  static String get aiUnauthorized => _t('resilience.ai_unauthorized');
  static String get aiAuthPending => _t('resilience.ai_auth_pending');
  static String get aiAppCheck => _t('resilience.ai_app_check');
  static String get aiEmptyResponse => _t('resilience.ai_empty');
  static String get aiResponseUnavailable => _t('resilience.ai_response');
  static String get aiRateLimited => _t('resilience.ai_rate');
  static String get cardDrawFailed => _t('resilience.card_draw_failed');
  static String get sessionInitFailed => _t('resilience.session_init');
  static String get interpretationFailed =>
      _t('resilience.interpretation_failed');
  static String get interpretationTimeout =>
      _t('resilience.interpretation_timeout');
  static String get oracleSendFailed => _t('resilience.oracle_send');
  static String get oracleRegenerateFailed => _t('resilience.oracle_regen');
  static String get memoryEmptyTitle => _t('resilience.memory_empty_title');
  static String get memoryEmptyBody => _t('resilience.memory_empty_body');
  static String get chatHistoryEmptyTitle => _t('resilience.chat_empty_title');
  static String get chatHistoryEmptyBody => _t('resilience.chat_empty_body');
  static String get bootstrapFailed => _t('resilience.bootstrap_failed');
  static String get profileLoadFailed => _t('resilience.profile_failed');
  static String get settingsSaveFailed => _t('resilience.settings_save_failed');
  static String get settingsLoadFailed => _t('resilience.settings_load_failed');
}

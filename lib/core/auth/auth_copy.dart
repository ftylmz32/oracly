/// User-facing auth copy — never Firebase/provider internals.
library;

import '../l10n/l10n.dart';

abstract final class AuthCopy {
  AuthCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get notConfigured => _t('auth.not_configured');
  static String get failed => _t('auth.failed');
  static String get invalidCredentials => _t('auth.invalid');
  static String get tooManyAttempts => _t('auth.too_many');
  static String get signedOut => _t('auth.signed_out');
  static String get signOutFailed => _t('auth.sign_out_failed');
  static String get noCurrentUser => _t('auth.no_current_user');
  static String get requiresRecentLogin => _t('auth.requires_recent_login');
  static String get deleteFailed => _t('auth.delete_failed');
}

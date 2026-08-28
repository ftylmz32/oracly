/// Blocks unsafe remote keys and copy — never secrets or credentials.
library;

abstract final class RemoteConfigSecurity {
  RemoteConfigSecurity._();

  static const allowedRootKeys = {
    'config_version',
    'min_app_version',
    'daily_message_weights',
    'gem_history_display_limit',
    'feature_flags',
    'copy_overrides',
    'experiments',
    'animation_intensity_cap',
    'notification_cadence_hours',
    'notification_daily_hour',
  };

  static final blockedKey = RegExp(
    r'secret|password|credential|api[_-]?key|token|billing|sk-|auth',
    caseSensitive: false,
  );

  static bool isAllowedRootKey(String key) =>
      allowedRootKeys.contains(key) && !blockedKey.hasMatch(key);

  static bool isSafeCopy(String value) {
    if (value.length > 160) return false;
    if (blockedKey.hasMatch(value)) return false;
    if (value.contains('@')) return false;
    return true;
  }
}

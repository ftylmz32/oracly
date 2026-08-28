/// Parses and validates remote config — invalid / unsupported never activate.
library;

import '../experiments/experiment_remote_config.dart';
import '../telemetry/app_release_info.dart';
import 'remote_config_defaults.dart';
import 'remote_config_security.dart';
import 'remote_config_snapshot.dart';
import 'remote_config_validation.dart';

abstract final class RemoteConfigValidator {
  RemoteConfigValidator._();

  static RemoteConfigSnapshot parse(Map<String, Object?>? raw) =>
      validate(raw).snapshot;

  static RemoteConfigValidation validate(Map<String, Object?>? raw) {
    final base = RemoteConfigDefaults.snapshot;
    if (raw == null || raw.isEmpty) {
      return RemoteConfigValidation.missing();
    }
    if (!_hasUsableKeys(raw)) {
      return RemoteConfigValidation.rejected();
    }
    final minVersion = _string(raw['min_app_version']);
    if (!_supportsApp(minVersion)) {
      return RemoteConfigValidation.unsupported();
    }

    return RemoteConfigValidation.accepted(
      base.merge(
        RemoteConfigSnapshot(
          configVersion: _int(raw['config_version'], base.configVersion),
          minAppVersion: minVersion,
          dailyMessageWeights: _weights(raw['daily_message_weights'], base),
          gemHistoryDisplayLimit: _int(
            raw['gem_history_display_limit'],
            base.gemHistoryDisplayLimit,
            min: 1,
            max: 12,
          ),
          featureFlags: _flags(raw['feature_flags'], base),
          copyOverrides: _copy(raw['copy_overrides']),
          experiments: ExperimentRemoteConfig.parse(raw['experiments']),
          animationIntensityCap: _cap(
            raw['animation_intensity_cap'],
            base.animationIntensityCap,
          ),
          notificationCadenceHours: _int(
            raw['notification_cadence_hours'],
            base.notificationCadenceHours,
            min: 12,
            max: 72,
          ),
          notificationDailyHour: _int(
            raw['notification_daily_hour'],
            base.notificationDailyHour,
            min: 8,
            max: 20,
          ),
        ),
      ),
    );
  }

  static bool _hasUsableKeys(Map<String, Object?> raw) {
    var usable = false;
    for (final key in raw.keys) {
      if (RemoteConfigSecurity.isAllowedRootKey(key)) usable = true;
    }
    return usable;
  }

  static bool _supportsApp(String? minVersion) {
    if (minVersion == null || minVersion.trim().isEmpty) return true;
    return _compareVersion(AppReleaseInfo.version, minVersion) >= 0;
  }

  static int _compareVersion(String current, String required) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final a = parts(current);
    final b = parts(required);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  static Map<String, double> _weights(Object? raw, RemoteConfigSnapshot base) {
    if (raw is! Map) return base.dailyMessageWeights;
    final out = <String, double>{};
    raw.forEach((key, value) {
      final k = key.toString().trim();
      if (RemoteConfigSecurity.blockedKey.hasMatch(k)) return;
      final n = _double(value);
      if (n == null || n < 0 || n > 1) return;
      out[k] = n;
    });
    return out.isEmpty ? base.dailyMessageWeights : out;
  }

  static Map<String, bool> _flags(Object? raw, RemoteConfigSnapshot base) {
    if (raw is! Map) return base.featureFlags;
    final out = <String, bool>{};
    raw.forEach((key, value) {
      final k = key.toString().trim();
      if (RemoteConfigSecurity.blockedKey.hasMatch(k)) return;
      final b = _bool(value);
      if (b == null) return;
      out[k] = b;
    });
    return out;
  }

  static Map<String, String> _copy(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((key, value) {
      final k = key.toString().trim();
      if (RemoteConfigSecurity.blockedKey.hasMatch(k)) return;
      final text = value?.toString().trim() ?? '';
      if (!RemoteConfigSecurity.isSafeCopy(text)) return;
      out[k] = text;
    });
    return out;
  }

  static String _cap(Object? raw, String fallback) {
    final value = raw?.toString().trim().toLowerCase();
    if (value == 'low' || value == 'medium' || value == 'high') return value!;
    return fallback;
  }

  static int _int(Object? raw, int fallback, {int? min, int? max}) {
    final n = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (n == null) return fallback;
    if (min != null && n < min) return fallback;
    if (max != null && n > max) return fallback;
    return n;
  }

  static double? _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  static bool? _bool(Object? raw) {
    if (raw is bool) return raw;
    final text = raw?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  static String? _string(Object? raw) {
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

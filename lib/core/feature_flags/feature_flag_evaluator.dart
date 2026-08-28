/// Evaluates product flags — invalid input falls back to safe defaults.
library;

import '../telemetry/app_release_info.dart';
import 'feature_flag_debug_overrides.dart';
import 'feature_flag_definition.dart';
import 'product_feature_flags.dart';

abstract final class FeatureFlagEvaluator {
  FeatureFlagEvaluator._();

  static Map<String, bool> evaluate(Map<String, bool> remoteFlags) {
    final resolved = <String, bool>{};
    for (final flag in ProductFeatureFlags.catalog) {
      resolved[flag.key] = _resolve(flag, remoteFlags);
    }
    return resolved;
  }

  static bool _resolve(
    FeatureFlagDefinition flag,
    Map<String, bool> remoteFlags,
  ) {
    try {
      if (!_supportsApp(flag.minAppVersion)) return flag.defaultValue;
      final debug = FeatureFlagDebugOverrides.read(flag.key);
      if (debug != null) return debug;
      final remote = remoteFlags[flag.key];
      if (remote != null) return remote;
      return flag.defaultValue;
    } catch (_) {
      return flag.defaultValue;
    }
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
}

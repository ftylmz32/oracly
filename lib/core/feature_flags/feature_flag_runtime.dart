/// Runtime access to resolved product feature flags.
library;

import 'feature_flag_evaluator.dart';
import 'product_feature_flags.dart';

abstract final class FeatureFlagRuntime {
  FeatureFlagRuntime._();

  static Map<String, bool> _values = ProductFeatureFlags.defaults();

  static void refreshFromRemote(Map<String, bool> remoteFlags) {
    try {
      _values = FeatureFlagEvaluator.evaluate(remoteFlags);
    } catch (_) {
      _values = ProductFeatureFlags.defaults();
    }
  }

  static bool isEnabled(String key, {bool? fallback}) {
    final definition = ProductFeatureFlags.definitionFor(key);
    if (definition == null) return fallback ?? false;
    try {
      return _values[key] ?? definition.defaultValue;
    } catch (_) {
      return fallback ?? false;
    }
  }
}

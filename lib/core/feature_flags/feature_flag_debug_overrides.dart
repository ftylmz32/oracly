/// Debug-only local overrides — ignored in profile and release builds.
library;

import 'package:flutter/foundation.dart';

import 'product_feature_flags.dart';

abstract final class FeatureFlagDebugOverrides {
  FeatureFlagDebugOverrides._();

  static final _values = <String, bool>{};

  static bool get canOverride => !kReleaseMode && kDebugMode;

  static bool? read(String key) {
    if (!canOverride) return null;
    return _values[key];
  }

  static void set(String key, bool? value) {
    if (!canOverride) return;
    if (value == null) {
      _values.remove(key);
      return;
    }
    if (ProductFeatureFlags.definitionFor(key) == null) return;
    _values[key] = value;
  }

  static void clear() {
    if (!canOverride) return;
    _values.clear();
  }
}

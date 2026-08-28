/// Debug-only experiment overrides — ignored in profile and release builds.
library;

import 'package:flutter/foundation.dart';

import 'product_experiments.dart';

abstract final class ExperimentDebugOverrides {
  ExperimentDebugOverrides._();

  static final _values = <String, String>{};

  static bool get canOverride => !kReleaseMode && kDebugMode;

  static String? read(String experimentId) {
    if (!canOverride) return null;
    return _values[experimentId];
  }

  static void set(String experimentId, String? variant) {
    if (!canOverride) return;
    if (variant == null || variant.isEmpty) {
      _values.remove(experimentId);
      return;
    }
    final definition = ProductExperiments.definitionFor(experimentId);
    if (definition == null || !definition.isValidVariant(variant)) return;
    _values[experimentId] = variant;
  }

  static void clear() {
    if (!canOverride) return;
    _values.clear();
  }
}

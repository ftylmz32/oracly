/// One product feature flag — safe default and version gate.
library;

import 'feature_flag_type.dart';

class FeatureFlagDefinition {
  const FeatureFlagDefinition({
    required this.key,
    required this.type,
    required this.defaultValue,
    this.minAppVersion,
  });

  final String key;
  final FeatureFlagType type;
  final bool defaultValue;
  final String? minAppVersion;
}

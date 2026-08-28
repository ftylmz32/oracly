/// Validates remote experiment activation — catalog + non-financial only.
library;

import 'experiment_definition.dart';
import 'experiment_security.dart';
import 'product_experiments.dart';

abstract final class ExperimentRemoteConfig {
  ExperimentRemoteConfig._();

  static Map<String, String> parse(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((key, value) {
      final id = key.toString().trim();
      if (id.isEmpty || !ExperimentSecurity.isAllowed(id)) return;
      final definition = ProductExperiments.definitionFor(id);
      if (definition == null) return;
      final mode = value?.toString().trim() ?? '';
      if (!_isAllowedMode(definition, mode)) return;
      out[id] = mode;
    });
    return out;
  }

  static bool _isAllowedMode(ExperimentDefinition definition, String mode) {
    if (mode.isEmpty || mode.length > 24) return false;
    if (mode == ExperimentSecurity.liveMode) return true;
    return definition.isValidVariant(mode);
  }
}

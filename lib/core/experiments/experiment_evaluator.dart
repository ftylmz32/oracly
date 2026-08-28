/// Resolves experiment variant — inactive experiments stay on control.
library;

import 'experiment_assigner.dart';
import 'experiment_assignment_store.dart';
import 'experiment_debug_overrides.dart';
import 'experiment_definition.dart';
import 'experiment_security.dart';

abstract final class ExperimentEvaluator {
  ExperimentEvaluator._();

  static String resolve({
    required ExperimentDefinition definition,
    required Map<String, String> remoteExperiments,
    required ExperimentAssignmentStore store,
    required String subjectId,
  }) {
    try {
      if (!ExperimentSecurity.isAllowed(definition.id)) {
        return definition.defaultVariant;
      }
      final debug = ExperimentDebugOverrides.read(definition.id);
      if (debug != null && definition.isValidVariant(debug)) return debug;

      final remote = remoteExperiments[definition.id]?.trim();
      if (remote == null || remote.isEmpty) return definition.defaultVariant;
      if (definition.isValidVariant(remote)) return remote;

      if (remote != ExperimentSecurity.liveMode) {
        return definition.defaultVariant;
      }

      final assignmentVariants = definition.assignmentVariants;
      if (assignmentVariants.isEmpty) return definition.defaultVariant;

      final cached = store.read(definition.id, definition.version);
      if (cached != null && definition.isValidVariant(cached)) return cached;

      final assigned = ExperimentAssigner.pick(
        subjectId: subjectId,
        experimentId: definition.id,
        version: definition.version,
        variants: assignmentVariants,
      );
      store.remember(definition.id, definition.version, assigned);
      return assigned;
    } catch (_) {
      return definition.defaultVariant;
    }
  }
}

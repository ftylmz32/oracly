/// Resolves product experiments from remote config and stable local assignment.
library;

import '../data/datasources/local_storage.dart';
import '../remote_config/remote_config_runtime.dart';
import 'experiment_assignment_store.dart';
import 'experiment_evaluator.dart';
import 'experiment_subject_id.dart';
import 'product_experiments.dart';

class ExperimentService {
  ExperimentService({required LocalStorage storage})
      : _store = ExperimentAssignmentStore(storage),
        _subjectId = ExperimentSubjectId.read(storage);

  final ExperimentAssignmentStore _store;
  final String _subjectId;

  String variant(String experimentId) {
    final definition = ProductExperiments.definitionFor(experimentId);
    if (definition == null) return 'control';
    return ExperimentEvaluator.resolve(
      definition: definition,
      remoteExperiments: RemoteConfigRuntime.snapshot.experiments,
      store: _store,
      subjectId: _subjectId,
    );
  }

  bool isActive(String experimentId) {
    final definition = ProductExperiments.definitionFor(experimentId);
    if (definition == null) return false;
    final remote = RemoteConfigRuntime.snapshot.experiments[experimentId]?.trim();
    return remote != null && remote.isNotEmpty;
  }
}

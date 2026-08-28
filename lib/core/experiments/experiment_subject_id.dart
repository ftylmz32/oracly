/// Anonymous stable subject id for experiment assignment — never user content.
library;

import '../data/datasources/local_storage.dart';

abstract final class ExperimentSubjectId {
  ExperimentSubjectId._();

  static const _key = 'experiment_subject_id_v1';

  static String read(LocalStorage storage) {
    final existing = storage.getString(_key)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _createToken();
    storage.setString(_key, created);
    return created;
  }

  static String _createToken() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = Object.hash(stamp, DateTime.now().hashCode).toUnsigned(32);
    return 'exp_$stamp$random';
  }
}

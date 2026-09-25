/// Exact artifact reopen — never calls provider / astronomy / cache.
library;

import 'yildizname_artifact.dart';
import 'yildizname_artifact_exceptions.dart';
import 'yildizname_artifact_integrity.dart';
import 'yildizname_artifact_repository.dart';

class YildiznameArtifactReopen {
  YildiznameArtifactReopen(this._repo);

  final YildiznameArtifactRepository _repo;

  /// Loads and verifies integrity. Returns null when missing.
  Future<YildiznameArtifact?> byId(String id) async {
    final artifact = await _repo.getById(id);
    if (artifact == null) return null;
    YildiznameArtifactIntegrity.verify(artifact);
    return artifact;
  }

  /// Same as [byId] but throws [YildiznameArtifactCorruptException] / missing.
  Future<YildiznameArtifact> requireById(String id) async {
    final artifact = await byId(id);
    if (artifact == null) {
      throw const YildiznameArtifactCorruptException('artifact not found');
    }
    return artifact;
  }
}

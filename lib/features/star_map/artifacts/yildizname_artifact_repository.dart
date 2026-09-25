/// Owner-safe Yıldızname artifact persistence.
library;

import 'yildizname_artifact.dart';

abstract class YildiznameArtifactRepository {
  Future<List<YildiznameArtifact>> getAll();

  Future<YildiznameArtifact?> getById(String id);

  /// Insert-only. Identical content returns existing; id conflict throws.
  Future<YildiznameArtifact> saveNew(YildiznameArtifact artifact);

  Future<void> delete(String id);

  Future<void> clearAllForOwner();
}

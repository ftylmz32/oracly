/// App-owned Coffee V3 working photos: the normalized JPEG copies the V3
/// normalizer writes as `{applicationSupport}/coffee_v3_work/coffee_v3_work_{micros}.jpg`.
/// ONLY these are ever deleted by V3 code — never a camera/gallery
/// original, never a V2 (`coffee_v2_work`), Palm or any other file, and
/// never an arbitrary path read from (untrusted) persisted metadata. The
/// strict ownership rules live in the shared [CoffeeOwnedWorkDir].
library;

import '../../../privacy/services/archive_path_kind.dart';
import '../../services/coffee_owned_work_dir.dart';

abstract final class CoffeeV3WorkFiles {
  CoffeeV3WorkFiles._();

  /// Must match the work-dir name the V3 normalizer passes to
  /// `ImageNormalizer.normalize` (which prefixes files with it).
  static const dirName = 'coffee_v3_work';
  static const filePrefix = '${dirName}_';

  static const _dir = CoffeeOwnedWorkDir(dirName);

  static Future<ArchivePathKind> classify(String? path) => _dir.classify(path);

  static Future<bool> isOwned(String? path) => _dir.isOwned(path);

  static Future<bool> deleteIfOwnedStrict(String? path) =>
      _dir.deleteIfOwnedStrict(path);

  static Future<bool> purgeStrict() => _dir.purgeStrict();
}

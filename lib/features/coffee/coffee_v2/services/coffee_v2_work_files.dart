/// App-owned Coffee V2 working photos: the normalized JPEG copies
/// `DefaultCoffeeV2Normalizer` writes as `{applicationSupport}/coffee_v2_work/coffee_v2_work_{micros}.jpg`.
/// ONLY these are ever deleted by V2 code — never a camera/gallery
/// original, never V3 (`coffee_v3_work`), Palm, archive or any other file,
/// and never an arbitrary path read from persisted metadata. Strict
/// ownership rules live in the shared [CoffeeOwnedWorkDir].
library;

import '../../../privacy/services/archive_path_kind.dart';
import '../../services/coffee_owned_work_dir.dart';

abstract final class CoffeeV2WorkFiles {
  CoffeeV2WorkFiles._();

  /// Must match the work-dir name `DefaultCoffeeV2Normalizer` passes to
  /// `ImageNormalizer.normalize`.
  static const dirName = 'coffee_v2_work';
  static const filePrefix = '${dirName}_';

  static const _dir = CoffeeOwnedWorkDir(dirName);

  static Future<ArchivePathKind> classify(String? path) => _dir.classify(path);

  static Future<bool> isOwned(String? path) => _dir.isOwned(path);

  static Future<bool> deleteIfOwnedStrict(String? path) =>
      _dir.deleteIfOwnedStrict(path);

  static Future<bool> purgeStrict() => _dir.purgeStrict();
}

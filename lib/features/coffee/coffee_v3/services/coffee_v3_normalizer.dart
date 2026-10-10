/// Coffee V3 normalization: the SAME proven V2 strategy (shared
/// `ImageNormalizer`, 8 MiB per-photo ceiling — V3 also stages one photo
/// per request) writing into its own `coffee_v3_work` directory so V3 temp
/// files never mix with V2's.
library;

import '../../../ai/production/transport/image_normalizer.dart';
import '../../coffee_v2/services/coffee_v2_image_limits.dart';
import '../../coffee_v2/services/coffee_v2_normalizer.dart';
import '../../models/coffee_image_pick.dart';
import 'coffee_v3_work_files.dart';

class DefaultCoffeeV3Normalizer implements CoffeeV2Normalizer {
  const DefaultCoffeeV3Normalizer(this.messages);

  final ImageNormalizeMessages messages;

  @override
  Future<CoffeeImagePick> normalize(CoffeeImagePick source) {
    return ImageNormalizer.normalize(
      source,
      CoffeeV3WorkFiles.dirName,
      messages,
      maxBytesOverride: CoffeeV2ImageLimits.maxBytes,
    );
  }
}

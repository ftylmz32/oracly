/// HEIC/HEIF + EXIF to app-private JPEG suitable for vision upload.
library;

import '../../ai/production/transport/image_normalizer.dart';
import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';

typedef CoffeeNormalizeException = ImageNormalizeException;
typedef CoffeeNormalizeKind = ImageNormalizeKind;

abstract final class CoffeeImageNormalizer {
  CoffeeImageNormalizer._();

  /// Decode/orient/compress into app-private working JPEG.
  static Future<CoffeeImagePick> normalize(CoffeeImagePick source) {
    return ImageNormalizer.normalize(
      source,
      'coffee_work',
      ImageNormalizeMessages(
        missing: CoffeeCopy.imageMissing,
        unreadable: CoffeeCopy.imageUnreadable,
        unsupported: CoffeeCopy.imageUnsupported,
        normalizeFailed: CoffeeCopy.imageNormalizeFailed,
        tooLarge: CoffeeCopy.imageTooLarge,
      ),
    );
  }
}

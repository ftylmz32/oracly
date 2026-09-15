/// HEIC/HEIF + EXIF to app-private JPEG suitable for vision upload.
library;

import '../../ai/production/transport/image_normalizer.dart';
import '../../coffee/models/coffee_image_pick.dart';
import '../copy/palm_copy.dart';

typedef PalmNormalizeException = ImageNormalizeException;
typedef PalmNormalizeKind = ImageNormalizeKind;

abstract final class PalmImageNormalizer {
  PalmImageNormalizer._();

  static const maxEdge = ImageNormalizer.maxEdge;
  static const quality = ImageNormalizer.quality;

  /// Decode/orient/compress into app-private working JPEG.
  static Future<CoffeeImagePick> normalize(CoffeeImagePick source) {
    return ImageNormalizer.normalize(
      source,
      'palm_work',
      ImageNormalizeMessages(
        missing: PalmCopy.imageMissing,
        unreadable: PalmCopy.imageUnreadable,
        unsupported: PalmCopy.imageUnsupported,
        normalizeFailed: PalmCopy.imageNormalizeFailed,
        tooLarge: PalmCopy.imageTooLarge,
      ),
    );
  }
}

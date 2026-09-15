/// Coffee V2's normalization strategy: reuse the exact same
/// orientation/JPEG/quality philosophy as legacy Coffee/Palm, through the
/// shared `ImageNormalizer`, but enforce the tighter 8 MiB V2 transport
/// ceiling via its additive `maxBytesOverride` parameter. `ImageNormalizer`
/// itself is never changed in behavior for any caller that omits it.
library;

import '../../../ai/production/transport/image_normalizer.dart';
import '../../models/coffee_image_pick.dart';
import 'coffee_v2_image_limits.dart';

/// Injectable seam so tests can control normalization outcomes
/// deterministically (oversized/corrupt/unsupported) without depending on
/// the real `flutter_image_compress` platform channel.
abstract class CoffeeV2Normalizer {
  Future<CoffeeImagePick> normalize(CoffeeImagePick source);
}

class DefaultCoffeeV2Normalizer implements CoffeeV2Normalizer {
  const DefaultCoffeeV2Normalizer(this.messages);

  final ImageNormalizeMessages messages;

  @override
  Future<CoffeeImagePick> normalize(CoffeeImagePick source) {
    return ImageNormalizer.normalize(
      source,
      'coffee_v2_work',
      messages,
      maxBytesOverride: CoffeeV2ImageLimits.maxBytes,
    );
  }
}

/// Placeholder English copy for this infrastructure-only phase — Phase 2C2
/// wires real localized `ImageNormalizeMessages` in through the same
/// constructor seam when the capture UI is built.
const coffeeV2DefaultNormalizeMessages = ImageNormalizeMessages(
  missing: 'Photo file could not be found.',
  unreadable: 'Photo file could not be read.',
  unsupported: 'Unsupported photo format.',
  normalizeFailed: 'Photo could not be processed.',
  tooLarge: 'Photo is too large.',
);

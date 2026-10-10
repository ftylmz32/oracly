/// The one place that decides how a Coffee reading's `overall` is shown.
library;

import '../../../core/copy/fortune_voice.dart';
import '../models/coffee_reading.dart';

abstract final class CoffeeResultText {
  CoffeeResultText._();

  /// `m2_public_v1`: the server's gated reading, EXACTLY (never scrubbed or
  /// trimmed). Legacy Coffee: the existing `FortuneVoice.scrub` polish.
  static String overall(CoffeeReading reading) =>
      reading.isM2PublicV1 ? reading.overall : FortuneVoice.scrub(reading.overall);
}

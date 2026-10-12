/// The one place that decides how a Coffee reading's `overall` is shown.
library;

import '../../../core/copy/fortune_voice.dart';
import '../models/coffee_reading.dart';

abstract final class CoffeeResultText {
  CoffeeResultText._();

  /// Server-gated V3 (`m2_public_v1` / `v3_narrative_v1`): the server's gated
  /// reading, EXACTLY (never scrubbed or trimmed). Legacy Coffee: the
  /// existing `FortuneVoice.scrub` polish.
  static String overall(CoffeeReading reading) =>
      reading.isServerGatedV3 ? reading.overall : FortuneVoice.scrub(reading.overall);
}

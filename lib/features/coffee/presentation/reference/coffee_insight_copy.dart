/// User-facing coffee insight for the clipboard — never ids or paths.
library;

import '../../../../core/copy/fortune_voice.dart';
import '../../../../core/insight_copy/insight_copy_text.dart';
import '../../copy/coffee_copy.dart';
import '../../models/coffee_reading.dart';
import '../../services/coffee_result_text.dart';

abstract final class CoffeeInsightCopy {
  CoffeeInsightCopy._();

  static String fromReading(CoffeeReading reading) {
    return InsightCopyText.joinBlocks([
      // m2_public_v1: the gated reading verbatim (no scrub, no robotic filter).
      reading.isM2PublicV1
          ? '${CoffeeCopy.overallTitle}\n${CoffeeResultText.overall(reading)}'
          : _lane(CoffeeCopy.overallTitle, reading.overall),
      _lane(CoffeeCopy.loveTitle, reading.love),
      _lane(CoffeeCopy.careerTitle, reading.career),
      _lane(CoffeeCopy.nearFutureTitle, reading.nearFuture),
      _lane(CoffeeCopy.takeawayTitle, reading.takeaway),
    ]);
  }

  static String _lane(String title, String source) {
    final body = FortuneVoice.scrub(source);
    if (body.isEmpty || FortuneVoice.looksRobotic(source)) return '';
    return '$title\n$body';
  }
}

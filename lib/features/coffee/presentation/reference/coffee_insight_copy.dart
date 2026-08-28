/// User-facing coffee insight for the clipboard — never ids or paths.
library;

import '../../../../core/copy/fortune_voice.dart';
import '../../../../core/insight_copy/insight_copy_text.dart';
import '../../copy/coffee_copy.dart';
import '../../models/coffee_reading.dart';

abstract final class CoffeeInsightCopy {
  CoffeeInsightCopy._();

  static String fromReading(CoffeeReading reading) {
    return InsightCopyText.joinBlocks([
      _lane(CoffeeCopy.overallTitle, reading.overall),
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

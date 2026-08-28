/// User-facing palm insight for the clipboard — never ids or paths.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/insight_copy/insight_copy_text.dart';
import '../copy/palm_copy.dart';
import '../models/palm_reading.dart';

abstract final class PalmInsightCopy {
  PalmInsightCopy._();

  static String fromReading(PalmReading reading) {
    return InsightCopyText.joinBlocks([
      _lane(PalmCopy.overallTitle, reading.overall),
      _lane(PalmCopy.heartTitle, reading.heartLine),
      _lane(PalmCopy.headTitle, reading.headLine),
      _lane(PalmCopy.lifeTitle, reading.lifeLine),
      _lane(PalmCopy.fateTitle, reading.fateLine),
    ]);
  }

  static String _lane(String title, String source) {
    final body = FortuneVoice.scrub(source);
    if (body.isEmpty || FortuneVoice.looksRobotic(source)) return '';
    return '$title\n$body';
  }
}
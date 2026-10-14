/// User-facing palm insight for the clipboard — never ids or paths.
library;

import '../../../core/insight_copy/insight_copy_text.dart';
import '../copy/palm_copy.dart';
import '../models/palm_reading.dart';
import '../services/palm_fortune_composer.dart';

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
    // Exactly what the result shows (server-gated text, never rewritten).
    final body = PalmFortuneComposer.section(source);
    if (body.isEmpty) return '';
    return '$title\n$body';
  }
}
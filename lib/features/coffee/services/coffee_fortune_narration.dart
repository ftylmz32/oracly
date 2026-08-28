/// One spoken cup reading. Optional asides only when a mark earned them.
library;

import '../../../core/copy/fortune_voice.dart';
import '../models/coffee_reading.dart';

abstract final class CoffeeFortuneNarration {
  CoffeeFortuneNarration._();

  static String body(CoffeeReading reading) {
    final parts = <String>[];
    final overall = FortuneVoice.scrub(reading.overall);
    if (overall.isNotEmpty) parts.add(overall);
    _aside(parts, reading.love);
    _aside(parts, reading.career);
    _aside(parts, reading.nearFuture);
    _aside(parts, reading.takeaway);
    return parts.join('\n\n');
  }

  static void _aside(List<String> parts, String source) {
    final text = FortuneVoice.scrub(source);
    if (text.isEmpty || FortuneVoice.looksRobotic(source)) return;
    if (parts.any((p) => p.contains(text))) return;
    parts.add(text);
  }
}

/// One spoken palm reading. Lines stay asides, never category tiles.
library;

import '../../../core/copy/fortune_voice.dart';
import '../models/palm_reading.dart';

abstract final class PalmFortuneNarration {
  PalmFortuneNarration._();

  static String body(PalmReading reading) {
    final parts = <String>[];
    _lead(parts, reading.overall);
    _aside(parts, reading.heartLine);
    _aside(parts, reading.headLine);
    _aside(parts, reading.lifeLine);
    _aside(parts, reading.fateLine);
    if (reading.symbols.isNotEmpty) {
      _aside(parts, reading.symbols.first);
    }
    return parts.join('\n\n');
  }

  static void _lead(List<String> parts, String source) {
    final text = FortuneVoice.scrub(source);
    if (text.isEmpty) return;
    parts.add(text);
  }

  static void _aside(List<String> parts, String source) {
    final text = FortuneVoice.scrub(source);
    if (text.isEmpty || FortuneVoice.looksRobotic(source)) return;
    if (parts.any((p) => p.contains(text))) return;
    parts.add(text);
  }
}

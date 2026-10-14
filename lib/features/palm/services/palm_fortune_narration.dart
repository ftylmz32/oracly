/// One spoken palm reading. Lines stay asides, never category tiles.
library;

import '../models/palm_reading.dart';
import 'palm_fortune_composer.dart';

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
    // Spoken exactly as shown (server-gated text, never rewritten).
    final text = PalmFortuneComposer.section(source);
    if (text.isEmpty) return;
    parts.add(text);
  }

  static void _aside(List<String> parts, String source) {
    final text = PalmFortuneComposer.section(source);
    if (text.isEmpty) return;
    if (parts.any((p) => p.contains(text))) return;
    parts.add(text);
  }
}

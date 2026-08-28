/// Vision facts only. Never adds length, breaks, branches, or medical claims.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../models/palm_reading.dart';

abstract final class PalmObservation {
  PalmObservation._();

  static const absent = [
    'görünmüyor',
    'görünmez',
    'yok',
    'not visible',
    'не видн',
    'too faint',
  ];

  static const unsure = [
    'net değil',
    'silik',
    'belirsiz',
    'faint',
    'unclear',
    'слабо',
    'неясно',
  ];

  static const textbook = [
    'temsil eder',
    'represents',
    'означает',
    'demektir',
    'şu anlama gelir',
    'means that',
    'uzun ömür',
    'lifespan',
    'yaşam süresi',
    'dallanma',
    'forked line',
    'break in the',
    'hastalık',
    'hastalığ',
    'ölüm',
    'death',
    'ömrün',
    'teşhis',
    'diagnosis',
    'prognosis',
  ];

  static String ground(String raw) {
    final scrubbed = HumanReader.guard(FortuneVoice.scrub(raw));
    if (scrubbed.isEmpty) return '';
    final kept = <String>[];
    for (final part in scrubbed.split(RegExp(r'(?<=[.!?])\s+'))) {
      final text = part.trim();
      if (text.isEmpty || _drop(text)) continue;
      kept.add(text);
    }
    return kept.join(' ').trim();
  }

  static String shapeOf(PalmReading raw) {
    final overall = ground(raw.overall);
    if (overall.isEmpty) return '';
    final first = overall.split(RegExp(r'(?<=[.!?])\s+')).first.trim();
    return _bare(first);
  }

  static String line(String observed) {
    final text = ground(observed);
    if (text.isEmpty || missing(text)) return '';
    return text;
  }

  static bool missing(String text) {
    final lower = text.toLowerCase();
    return text.trim().isEmpty || absent.any(lower.contains);
  }

  static bool uncertain(String text) {
    final lower = text.toLowerCase();
    return unsure.any(lower.contains);
  }

  static List<String> marks(Iterable<String> names) => [
        for (final name in names)
          if (name.trim().isNotEmpty) name.trim(),
      ];

  static String clip(String text) {
    var out = _bare(text.trim());
    if (out.length <= 88) return out;
    out = out.substring(0, 88);
    final cut = out.lastIndexOf(' ');
    return cut > 24 ? out.substring(0, cut) : out;
  }

  static bool _drop(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('=')) return true;
    if (textbook.any(lower.contains)) return true;
    if (FortuneVoice.claimsMedical(text)) return true;
    if (FortuneVoice.claimsCertainty(text)) return true;
    return FortuneVoice.looksRobotic(text);
  }

  static String _bare(String text) {
    if (text.isEmpty) return text;
    final last = text[text.length - 1];
    if (last == '.' || last == '!' || last == '?') {
      return text.substring(0, text.length - 1).trim();
    }
    return text;
  }
}

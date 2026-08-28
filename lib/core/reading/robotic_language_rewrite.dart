/// Bounded rewrite when robotic repetition scores high — variation, not censorship.
library;

import 'human_reader_guard.dart';
import 'robotic_language_detector.dart';

abstract final class RoboticLanguageRewrite {
  RoboticLanguageRewrite._();

  static String bounded(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final report = RoboticLanguageDetector.analyze(trimmed);
    if (!report.needsRewrite) return trimmed;

    var out = HumanReaderGuard.scrub(trimmed);
    out = _stripHeadings(out);
    out = _varyOpeners(out);
    out = _dedupeSentences(out);
    return out.replaceAll(RegExp(r'\n{3,}'), '\n\n').replaceAll(RegExp(r'  +'), ' ').trim();
  }

  static String _stripHeadings(String text) {
    var out = text;
    out = out.replaceAll(RegExp(r'^#{1,3}\s+.+$', multiLine: true), '');
    out = out.replaceAll(
      RegExp(
        r'^(ANA HİS|SEMBOLİK YORUM|DİKKAT ÇEKEN DETAY|KİŞİSEL BAĞLAM|GENEL YORUM)\s*:?\s*',
        multiLine: true,
        caseSensitive: false,
      ),
      '',
    );
    return out.trim();
  }

  static String _varyOpeners(String text) {
    var card = 0;
    var dream = 0;
    return text.replaceAllMapped(
      RegExp(r'(^|[.!?]\s+)(Bu (kart|rüya))', caseSensitive: false),
      (m) {
        final lead = m.group(1) ?? '';
        final kind = (m.group(3) ?? '').toLowerCase();
        if (kind == 'kart') {
          card++;
          if (card == 1) return m.group(0)!;
          final alt = card == 2 ? 'Kartta' : 'Burada kartta';
          return '$lead$alt';
        }
        dream++;
        if (dream == 1) return m.group(0)!;
        final alt = dream == 2 ? 'Rüyada' : 'Burada rüyada';
        return '$lead$alt';
      },
    );
  }

  static String _dedupeSentences(String text) {
    final parts = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (parts.length < 2) return text;
    final kept = <String>[];
    String? prevKey;
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final prefix = key.length > 28 ? key.substring(0, 28) : key;
      if (prefix == prevKey) continue;
      kept.add(trimmed);
      prevKey = prefix;
    }
    return kept.join(' ');
  }
}

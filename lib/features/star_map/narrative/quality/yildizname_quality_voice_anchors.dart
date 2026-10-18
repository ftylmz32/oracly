/// Repeated motifs across blocks. Inflection is folded; one block never counts.
library;

import 'yildizname_lexical_token.dart';

abstract final class YildiznameVoiceAnchors {
  YildiznameVoiceAnchors._();

  static final _word = RegExp(
    r"[0-9A-Za-z_\u00C0-\u024F\u0400-\u04FF']+",
  );
  static final _houseNum = RegExp(r'(\d+)\s*\.\s*ev', caseSensitive: false);

  static const _stops = {
    'olarak',
    'içinde',
    'üzerinde',
    'arasında',
    'birlikte',
    'çünkü',
    'değil',
    'kadar',
    'sonra',
    'önce',
    'kendi',
    'ancak',
    'fakat',
    'olan',
    'bunun',
    'şunun',
    'vardır',
    'yoktur',
    'şeyin',
    'zaman',
    'yerde',
  };

  static const _suffixes = [
    'lerden', 'lardan', 'lerde', 'larda', 'lerin', 'ların',
    'ler', 'lar', 'den', 'dan', 'ten', 'tan', 'nin', 'nın',
    'nun', 'nün', 'de', 'da', 'te', 'ta', 'ın', 'in', 'un', 'ün',
  ];

  /// Stems and house-number tokens present in at least [minBlocks] blocks.
  static List<String> repeated(List<String> blocks, {int minBlocks = 5}) {
    final counts = <String, int>{};
    for (final block in blocks) {
      final seen = <String>{};
      final text = YildiznameLexicalToken.normalizeProse(block.toLowerCase());
      for (final m in _word.allMatches(text)) {
        final stem = _stem(m.group(0)!);
        if (stem.length < 5 || _stops.contains(stem)) continue;
        if (stem.contains('ebilir') || stem.contains('abilir')) continue;
        seen.add(stem);
      }
      for (final h in _houseNum.allMatches(text)) {
        seen.add('house:${h.group(1)}');
      }
      for (final token in seen) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
    }
    return [
      for (final e in counts.entries)
        if (e.value >= minBlocks) e.key,
    ]..sort();
  }

  static String _stem(String raw) {
    var s = raw.replaceAll(RegExp(r"'.*$"), '');
    s = s.replaceAll(RegExp(r"[^0-9a-zçğıöşüı]"), '');
    for (var pass = 0; pass < 2; pass++) {
      var cut = false;
      for (final suf in _suffixes) {
        if (s.length - suf.length >= 5 && s.endsWith(suf)) {
          s = s.substring(0, s.length - suf.length);
          cut = true;
          break;
        }
      }
      if (!cut) break;
    }
    return s;
  }
}

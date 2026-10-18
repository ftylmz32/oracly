/// Structural signals for Yıldızname voice — ratios, not a banned-word list.
library;

import 'yildizname_grounding_lexicon.dart';
import 'yildizname_lexical_token.dart';
import 'yildizname_quality_voice_pile.dart';

/// Counts how a reading is built. Policy thresholds live in the voice gate.
abstract final class YildiznameVoiceScan {
  YildiznameVoiceScan._();

  static final _word = RegExp(
    r"[0-9A-Za-z_\u00C0-\u024F\u0400-\u04FF']+",
  );
  static final _sentence = RegExp(r'[^!.?;…]+');
  static final _hedge = RegExp(
    r'(?:ebilir|abilir|düşündür|gösteriyor|görünüyor|'
    r'\bmay\b|\bmight\b|\bcould\b|\bsuggests\b|\binvites\b|может|возможно)',
    caseSensitive: false,
  );
  static final _address = RegExp(
    r"(?<![0-9A-Za-z_\u00C0-\u024F])"
    r'(?:seni|sana|sende|senden|senin|sen|you|your|ты|тебе|тебя)',
    caseSensitive: false,
  );
  static final _meta = RegExp(
    r'haritan|the chart|карт',
    caseSensitive: false,
  );
  static final _jargon = YildiznameLexicalToken.compile(_jargonSource());

  static int words(String text) => _word.allMatches(_norm(text)).length;

  static List<String> sentences(String text) => [
        for (final m in _sentence.allMatches(_norm(text)))
          if (m.group(0)!.trim().length >= 12) m.group(0)!.trim(),
      ];

  static int jargonHits(String text) =>
      _jargon.allMatches(_norm(text)).length;

  static int hedgedSentences(List<String> sentences) =>
      sentences.where(_hedge.hasMatch).length;

  static int technicalSentences(List<String> sentences) {
    var n = 0;
    for (final sentence in sentences) {
      final hits = _jargon.allMatches(sentence).length;
      if (hits >= 2) {
        n++;
        continue;
      }
      final head = sentence.split(RegExp(r'\s+')).take(8).join(' ');
      if (hits >= 1 && _jargon.hasMatch(head)) n++;
    }
    return n;
  }

  static int abstractPiles(List<String> sentences) =>
      YildiznameVoicePile.count(sentences);

  static bool reportOpening(String summary) {
    final first = sentences(summary);
    if (first.isEmpty) return false;
    final line = first.first;
    return !_address.hasMatch(line) && _meta.hasMatch(line);
  }

  static String _norm(String text) =>
      YildiznameLexicalToken.normalizeProse(text.toLowerCase());

  static String _jargonSource() {
    final parts = <String>[
      for (final tokens in YildiznameGroundingLexicon.bodies.values)
        YildiznameLexicalToken.anyBody(tokens),
      for (final tokens in YildiznameGroundingLexicon.signs.values)
        YildiznameLexicalToken.anySign(tokens),
      for (final tokens in YildiznameGroundingLexicon.aspectWords.values)
        YildiznameLexicalToken.anyAspect(tokens),
      YildiznameLexicalToken.start('altmış'),
      YildiznameLexicalToken.start('altmis'),
      'tepe\\s+noktas',
      'sabit\\s+nitelik',
      '\\d+\\s*\\.?\\s*${YildiznameLexicalToken.house()}',
    ];
    return '(?:${parts.join('|')})';
  }
}

/// A pile is a catalogue of three or more real abstract nouns.
///
/// `-lık` counts only when it ends the noun. `sağlıklı` is an adjective.
/// A natural pair, `kadar`, or `karşılık bulmak` is not a pile by itself.
library;

import 'yildizname_lexical_token.dart';

abstract final class YildiznameVoicePile {
  YildiznameVoicePile._();

  static final _token = RegExp(
    r"[0-9A-Za-z_\u00C0-\u024F\u0400-\u04FF']+|,",
  );

  /// Noun suffix at the end of the word, then noun inflection only.
  static final _noun = RegExp(
    '(?:lık|lik|luk|lük|lığ|liğ|luğ|lüğ|iyet)'
    '(?:'
    'l[ae]r(?:[ıiuü](?:n(?:[ıiuü]n)?|d[ae]n?)?|[dt][ae]n?)?'
    '|[ıiuü]n[ıiuü]n'
    '|[ıiuü]nd[ae]n?'
    '|[ıiuü]n'
    '|[ıiuü]'
    '|n[ıiuü]n'
    '|n'
    r')?$',
    caseSensitive: false,
  );

  static const _glue = {'ve', 'ile', 'hem', 'ya', 'da', 'de', 'and'};

  static int count(List<String> sentences) {
    var piles = 0;
    for (final sentence in sentences) {
      if (isPile(sentence)) piles++;
    }
    return piles;
  }

  /// True when abstract nouns form one list of three or more.
  static bool isPile(String sentence) {
    final source = YildiznameLexicalToken.normalizeProse(sentence.toLowerCase());
    final tokens = [
      for (final match in _token.allMatches(source)) match.group(0)!,
    ];
    final nouns = <int>[];
    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i] == ',' || !_isNoun(tokens[i])) continue;
      final next = _nextWord(tokens, i);
      if (next != null && next.startsWith('bul')) continue;
      nouns.add(i);
    }
    var run = 1;
    for (var i = 1; i < nouns.length; i++) {
      if (_listed(tokens, nouns[i - 1], nouns[i])) {
        run++;
        if (run >= 3) return true;
      } else {
        run = 1;
      }
    }
    return false;
  }

  static bool _isNoun(String word) => _noun.hasMatch(word);

  static String? _nextWord(List<String> tokens, int index) {
    for (var i = index + 1; i < tokens.length; i++) {
      if (tokens[i] != ',') return tokens[i];
    }
    return null;
  }

  /// Commas, conjunctions, and one ordinary word keep a list intact.
  static bool _listed(List<String> tokens, int from, int to) {
    var extras = 0;
    for (var i = from + 1; i < to; i++) {
      final token = tokens[i];
      if (token == ',' || _glue.contains(token)) continue;
      extras++;
      if (extras > 1) return false;
    }
    return true;
  }
}

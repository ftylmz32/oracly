/// Dream Phase 4C — mechanical comparison of a provider field with the text
/// the client finally displays. Thresholds are a proxy, not a semantic
/// judgement: "meaningfully_changed" only means more than a fifth of the
/// words differ.
library;

const rewriteLexicalLimit = 0.2;

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[\s\p{P}\p{S}]+', unicode: true), ' ')
    .trim();

List<String> _words(String s) =>
    _norm(s).split(' ').where((w) => w.isNotEmpty).toList();

int _lcs(List<String> a, List<String> b) {
  var prev = List<int>.filled(b.length + 1, 0);
  for (final x in a) {
    final row = List<int>.filled(b.length + 1, 0);
    for (var j = 0; j < b.length; j++) {
      row[j + 1] = x == b[j]
          ? prev[j] + 1
          : (row[j] > prev[j + 1] ? row[j] : prev[j + 1]);
    }
    prev = row;
  }
  return prev[b.length];
}

/// Share of words not kept in order between [a] and [b] (0 = same words).
double wordEditRatio(String a, String b) {
  final wa = _words(a), wb = _words(b);
  final longest = wa.length > wb.length ? wa.length : wb.length;
  if (longest == 0) return 0;
  return 1 - _lcs(wa, wb) / longest;
}

/// unchanged · format_only · lexically_changed · meaningfully_changed ·
/// rejected (nothing of the field was displayed as provider prose).
String rewriteClass(String original, String? displayed) {
  if (displayed == null) return 'rejected';
  if (displayed == original) return 'unchanged';
  if (_norm(displayed) == _norm(original)) return 'format_only';
  return wordEditRatio(original, displayed) <= rewriteLexicalLimit
      ? 'lexically_changed'
      : 'meaningfully_changed';
}

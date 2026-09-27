/// Deterministic text mechanics shared by the Dream safety input policy and
/// output firewall. Mirrored in `backend/src/ai/dream-safety.ts`.
library;

class DreamSafetySegment {
  const DreamSafetySegment(this.text, {required this.question});

  final String text;
  final bool question;
}

abstract final class DreamSafetyText {
  DreamSafetyText._();

  static final _segment = RegExp(r'[^.!?…;:\n\[\]]+[.!?…;:\n\[\]]*');
  static final _trail = RegExp(r'[.!?…;:\n\[\]]+$');
  static final _apostrophe = RegExp('[’‘`´]');
  static final _spaces = RegExp(r'[ \t\u00A0]+');
  static final _word = RegExp(r"[\p{L}']+", unicode: true);

  static const _before = {
    'not', 'never', 'no', 'nobody', 'nothing', "don't", 'dont', "doesn't",
    "didn't", "won't", 'cannot', "can't", "isn't", "aren't", "wasn't",
    "shouldn't", 'if', 'whether', 'не', 'нет', 'никогда', 'нельзя', 'ни',
    'никто', 'ли', 'если', 'eğer', 'kimse', 'hiç',
  };
  static const _after = {
    'değil', 'değildir', 'gelmez', 'kanitlamaz', 'göstermez', 'doğrulamaz',
  };

  /// Lowercase; Turkish dotted/dotless i and Russian ё folded; apostrophes
  /// unified. Newlines survive so guided answers stay separate segments.
  static String fold(String text) => text
      .toLowerCase()
      .replaceAll('\u0307', '')
      .replaceAll('ı', 'i')
      .replaceAll('ё', 'е')
      .replaceAll(_apostrophe, "'")
      .replaceAll(_spaces, ' ');

  static List<DreamSafetySegment> segments(String raw) => [
        for (final m in _segment.allMatches(fold(raw)))
          if (m[0]!.replaceAll(_trail, '').trim() case final body
              when body.isNotEmpty)
            DreamSafetySegment(body, question: m[0]!.contains('?')),
      ];

  /// Alternatives anchored at a word start.
  static RegExp words(List<String> alternatives) => RegExp(
        '(?<![\\p{L}\\p{N}])(?:${alternatives.join('|')})',
        unicode: true,
      );

  static bool has(RegExp pattern, String text) => pattern.hasMatch(text);

  /// A match counts unless it sits inside dream framing ([dream] marker
  /// earlier in the segment with no [waking] marker in between) or, when
  /// [negationAware], it is negated or hedged.
  static bool hit(
    RegExp pattern,
    String text, {
    RegExp? dream,
    RegExp? waking,
    bool negationAware = false,
  }) {
    for (final m in pattern.allMatches(text)) {
      if (dream != null && _framed(text, m.start, dream, waking)) continue;
      if (negationAware && _negated(text, m.start, m.end)) continue;
      return true;
    }
    return false;
  }

  static bool _framed(String text, int at, RegExp dream, RegExp? waking) {
    int? frameEnd;
    for (final d in dream.allMatches(text)) {
      if (d.end <= at) frameEnd = d.end;
    }
    if (frameEnd == null) return false;
    if (waking == null) return true;
    return !waking
        .allMatches(text)
        .any((w) => w.start >= frameEnd! && w.start < at);
  }

  static bool _negated(String text, int start, int end) {
    final before = _word.allMatches(text.substring(0, start)).toList();
    final window = before.skip(before.length > 6 ? before.length - 6 : 0);
    if (window.any((w) => _before.contains(w[0]))) return true;
    final after = _word.allMatches(text.substring(end)).take(4);
    return after.any((w) => _after.contains(w[0]));
  }
}

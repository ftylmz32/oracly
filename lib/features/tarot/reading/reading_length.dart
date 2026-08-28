/// Spoken length — short questions and small spreads stay short.
library;

abstract final class ReadingLength {
  ReadingLength._();

  static int narrativeMax(int cards) {
    if (cards <= 1) return 6;
    if (cards <= 3) return 12;
    if (cards <= 5) return 18;
    return 24;
  }

  static int narrativeMin(int cards) {
    if (cards <= 1) return 3;
    if (cards <= 3) return 6;
    if (cards <= 5) return 10;
    return 12;
  }

  static List<String> sentences(String text) {
    return RegExp(r'[^.!?…]+[.!?…]?')
        .allMatches(text.trim())
        .map((m) => m.group(0)?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String clip(String text, int max) {
    final parts = sentences(text);
    if (parts.isEmpty) return text.trim();
    if (parts.length <= max) return parts.join(' ');
    return parts.take(max).join(' ');
  }

  static String keep(
    String text, {
    required String mustContain,
    String? also,
    required int max,
  }) {
    var clipped = clip(text, max);
    final tokens = [mustContain, if (also != null && also.isNotEmpty) also];
    for (final token in tokens) {
      if (clipped.toLowerCase().contains(token.toLowerCase())) continue;
      final extra = sentences(text).where(
        (s) => s.toLowerCase().contains(token.toLowerCase()),
      );
      if (extra.isEmpty) continue;
      var parts = sentences(clipped);
      while (parts.length >= max && parts.length > 2) {
        parts.removeAt(parts.length ~/ 2);
      }
      clipped = clip('${parts.join(' ')} ${extra.first}', max);
    }
    return clipped;
  }
}

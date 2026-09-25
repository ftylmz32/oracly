/// Whole-word-ish body presence helper (avoids `ay` matching `may`).
library;

abstract final class YildiznameBodyMatch {
  YildiznameBodyMatch._();

  static final _moon = RegExp(
    r'(?:^|[^a-zA-Zа-яА-ЯёЁ])(?:moon|лун\w*|ay(?:ı|ın|a|da|dan)?|Ay)(?=$|[^a-zA-Zа-яА-ЯёЁ])',
  );

  static bool has(String prose, String body, List<String> tokens) {
    if (body == 'moon') return _moon.hasMatch(prose);
    final padded = ' ${prose.toLowerCase()} ';
    for (final t in tokens) {
      final tip = t.trim().toLowerCase();
      if (tip.isEmpty) continue;
      if (padded.contains(tip)) return true;
    }
    return false;
  }
}

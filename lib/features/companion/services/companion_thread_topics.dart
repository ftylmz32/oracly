/// Observable topics in OR chat — never inferred identity.
library;

import '../data/companion_intent.dart';

abstract final class CompanionThreadTopics {
  CompanionThreadTopics._();

  static const scan = 24;

  static String? of(String? raw) {
    final t = (raw ?? '').toLowerCase();
    if (t.trim().isEmpty) return null;
    if (CompanionIntent.isKnowledge(t) || CompanionIntent.isPythonAsync(t)) {
      return null;
    }
    // Ritual domains before job — "işimle" alone must not steal a coffee ask.
    if (_affirmed(t, RegExp(r'kahve|fincan'))) return 'kahve';
    if (_affirmed(t, RegExp(r'tarot|kart|açılım|acilim'))) return 'tarot';
    if (_affirmed(t, RegExp(r'rüya|ruya|dream|сон'))) return 'rüya';
    if (_affirmed(t, RegExp(r'aşk|ask|ilişki|iliski|sevg'))) return 'ilişki';
    if (_affirmed(t, RegExp(r'iş|kariyer|meslek|\bjob\b|career|работ'))) {
      return 'iş';
    }
    if (_affirmed(
      t,
      RegExp(r'kararsız|karar|kafam karış|kafa.? karış|confused'),
    )) {
      return 'kararsızlık';
    }
    if (_affirmed(t, RegExp(r'sıkkın|yorgun|üzgün|bunal'))) return 'sıkıntı';
    return null;
  }

  /// The named topic appears, and every mention is denied ("iş değil").
  static bool denies(String text, String? topic) {
    final pattern = _patternFor(topic);
    if (pattern == null) return false;
    final lower = text.toLowerCase();
    var saw = false;
    for (final match in pattern.allMatches(lower)) {
      saw = true;
      if (!_negatedAt(lower, match.end)) return false;
    }
    return saw;
  }

  static bool _affirmed(String text, RegExp pattern) {
    for (final match in pattern.allMatches(text)) {
      if (!_negatedAt(text, match.end)) return true;
    }
    return false;
  }

  /// "iş değil" / "işim değil" — not "iş konusunda değil".
  static bool _negatedAt(String text, int end) {
    final after = text.substring(end);
    return RegExp(r'^[a-züğışöçâîû]{0,8}\s+(değil|degil)\b').hasMatch(after);
  }

  static RegExp? _patternFor(String? topic) => switch (topic) {
    'kahve' => RegExp(r'kahve|fincan'),
    'tarot' => RegExp(r'tarot|kart|açılım|acilim'),
    'rüya' => RegExp(r'rüya|ruya|dream|сон'),
    'ilişki' => RegExp(r'aşk|ask|ilişki|iliski|sevg'),
    'iş' => RegExp(r'iş|kariyer|meslek|\bjob\b|career|работ'),
    'kararsızlık' => RegExp(
      r'kararsız|karar|kafam karış|kafa.? karış|confused',
    ),
    'sıkıntı' => RegExp(r'sıkkın|yorgun|üzgün|bunal'),
    _ => null,
  };

  static bool isVague(String? topic) =>
      topic == 'kararsızlık' || topic == 'sıkıntı';

  static bool isTimeSpan(String text) {
    final t = text.trim().toLowerCase().replaceAll(RegExp(r'[.!?…]+$'), '');
    if (t.isEmpty || t.length > 40) return false;
    return RegExp(
      r'^(yaklaşık\s+)?('
      r'\d+\s*(gündür|aydır|haftadır|yıldır|gün|ay|hafta|yıl|sene)|'
      r'(bir|iki|üç|dört|beş|altı)\s*(gündür|aydır|haftadır|yıldır)|'
      r'uzun zamandır|bir süredir|dün|bugün|geçen hafta'
      r')$',
    ).hasMatch(t);
  }

  static bool isPin(String text) {
    final t = text.trim();
    if (t.length > 40) return false;
    if (isElaboration(t)) return false;
    if (CompanionIntent.isGreeting(t)) return false;
    final topic = of(t);
    return topic != null && !isVague(topic);
  }

  static bool isElaboration(String text) {
    final t = text.toLowerCase();
    return RegExp(
      r'kork|hisset|düşünüyorum|endişe|sıkış|üzül|istiyor',
    ).hasMatch(t);
  }
}

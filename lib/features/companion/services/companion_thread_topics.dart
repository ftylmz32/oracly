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
    if (RegExp(r'kahve|fincan').hasMatch(t)) return 'kahve';
    if (RegExp(r'tarot|kart|açılım').hasMatch(t)) return 'tarot';
    if (t.contains('rüya') || t.contains('dream') || t.contains('сон')) {
      return 'rüya';
    }
    if (RegExp(r'aşk|ilişki|sevg').hasMatch(t)) return 'ilişki';
    if (RegExp(r'iş|kariyer|meslek|\bjob\b|career|работ').hasMatch(t)) {
      return 'iş';
    }
    if (RegExp(r'kararsız|karar|kafam karış|kafa.? karış|confused').hasMatch(t)) {
      return 'kararsızlık';
    }
    if (RegExp(r'sıkkın|yorgun|üzgün|bunal').hasMatch(t)) return 'sıkıntı';
    return null;
  }

  static bool isVague(String? topic) =>
      topic == 'kararsızlık' || topic == 'sıkıntı';

  static bool isTimeSpan(String text) {
    final t = text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?…]+$'), '');
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

/// Resolves short follow-ups against the last user turn.
library;

import '../../companion/data/companion_intent.dart';

abstract final class FollowupQuestionResolve {
  FollowupQuestionResolve._();

  static String expand({
    required String current,
    List<String> priorUser = const [],
    bool sameThread = false,
    bool switched = false,
  }) {
    final q = current.trim();
    if (q.isEmpty || priorUser.isEmpty || switched) return q;
    if (CompanionIntent.isGreeting(q) || !_isFollowUp(q, sameThread: sameThread)) {
      return q;
    }
    final last = priorUser.last.trim();
    if (last.isEmpty || last.toLowerCase() == q.toLowerCase()) return q;
    return '$last — $q';
  }

  static bool _isFollowUp(String q, {required bool sameThread}) {
    final lower = q.toLowerCase();
    if (CompanionIntent.isGreeting(q)) return false;
    if (_isTimeSpan(q)) return true;
    const leads = [
      'peki',
      'ya ',
      'peki ya',
      'karşı taraf',
      'açısından',
      'daha çok',
      'o zaman',
      'peki o',
    ];
    if (leads.any(lower.contains)) return true;
    if (sameThread && q.length <= 56) return true;
    return q.length <= 16;
  }

  static bool _isTimeSpan(String text) {
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
}

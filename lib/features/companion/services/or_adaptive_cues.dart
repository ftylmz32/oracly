/// Detection helpers for adaptive conversation registers.
library;

import '../../ai/production/models/conversation_turn.dart';

abstract final class OrAdaptiveCues {
  OrAdaptiveCues._();

  static bool wantsConcise(String lower, String raw) =>
      raw.length <= 18 ||
      lower.contains('kısa tut') ||
      lower.contains('kisa tut') ||
      lower.contains('kısaca') ||
      lower.contains('kisaca') ||
      lower.contains('özetle') ||
      lower.contains('briefly') ||
      lower.contains('keep it short') ||
      lower.contains('коротко');

  static bool wantsDeep(
    String lower,
    String raw,
    List<ConversationTurn> turns,
  ) {
    if (lower.contains('detaylı') ||
        lower.contains('detayli') ||
        lower.contains('derinlemesine') ||
        lower.contains('in detail') ||
        lower.contains('подробно')) {
      return true;
    }
    if (raw.length > 160) return true;
    final priorLong =
        turns.where((x) => x.isUser && x.text.trim().length > 100).length;
    return priorLong >= 2 && raw.length > 80;
  }

  static bool technical(String lower) =>
      lower.contains('python') ||
      lower.contains('api') ||
      lower.contains('kod') ||
      lower.contains('code') ||
      lower.contains('nasıl çalışır') ||
      lower.contains('nasil calisir') ||
      lower.contains('how does') ||
      lower.contains('function') ||
      lower.contains('algorithm');

  static bool factual(String lower) =>
      lower.contains('gerçek mi') ||
      lower.contains('gercek mi') ||
      lower.contains('doğru mu') ||
      lower.contains('dogru mu') ||
      lower.contains('kanıt') ||
      lower.contains('kanit') ||
      lower.contains('is it true') ||
      lower.contains('evidence') ||
      lower.contains('fact') ||
      lower.startsWith('ne zaman') ||
      lower.startsWith('kim ') ||
      lower.startsWith('what is') ||
      lower.startsWith('when ');
}

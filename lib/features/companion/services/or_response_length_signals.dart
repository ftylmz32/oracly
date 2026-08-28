/// Signals for OR response-length scoring — never invents meaning.
library;

import '../../ai/production/models/conversation_turn.dart';
import '../data/companion_intent.dart';
import 'companion_thread_memory.dart';

abstract final class OrResponseLengthSignals {
  OrResponseLengthSignals._();

  static int base(String text) {
    if (text.isEmpty) return 0;
    if (CompanionIntent.isGreeting(text) && text.length <= 24) return 0;
    if (text.length <= 20) return 0;
    return 1;
  }

  static int complexity(String text) {
    var n = 0;
    if (text.length > 110) n++;
    if (text.length > 200) n++;
    if (RegExp(r'[?？]').allMatches(text).length >= 2) n++;
    if (text.contains('\n')) n++;
    final t = text.toLowerCase();
    if (_any(t, const ['çünkü', 'cunku', 'ama ', 'fakat', 'because'])) n++;
    if (CompanionIntent.isKnowledge(text)) n++;
    return n > 2 ? 2 : n;
  }

  static int emotional(String text) {
    var n = CompanionIntent.isLow(text) ? 1 : 0;
    final t = text.toLowerCase();
    if (_any(t, const [
      'korku', 'korkuyorum', 'yalnız', 'yalniz', 'öfke', 'ofke', 'panik',
      'ağlıyorum', 'agliyorum', 'afraid', 'lonely', 'anxious', 'страх',
    ])) {
      n++;
    }
    return n > 2 ? 2 : n;
  }

  static int importance(String text) {
    var n = 0;
    if (CompanionIntent.isJobChange(text)) n++;
    if (CompanionIntent.isAdvice(text)) n++;
    if (CompanionIntent.isUndecided(text)) n++;
    final t = text.toLowerCase();
    if (_any(t, const [
      'karar', 'ilişki', 'iliski', 'ayrılık', 'ayrilik', 'evlilik', 'aile',
      'decision', 'relationship', 'breakup', 'решен', 'отношен',
    ])) {
      n++;
    }
    return n > 2 ? 2 : n;
  }

  static int context(List<ConversationTurn> turns, String text) {
    if (turns.isEmpty) return 0;
    final memory = CompanionThreadMemory.read(turns, text);
    var n = 0;
    if (memory.continuing) n++;
    if (memory.answeringPrompt) n++;
    if ((memory.recap?.length ?? 0) > 80) n++;
    return n > 2 ? 2 : n;
  }

  static bool warrantsDeep(String text, List<ConversationTurn> turns) {
    if (text.length > 180 && (emotional(text) + importance(text)) >= 2) {
      return true;
    }
    return turns.length >= 4 && text.length > 100 && importance(text) >= 1;
  }

  static bool _any(String hay, List<String> needles) {
    for (final n in needles) {
      if (hay.contains(n)) return true;
    }
    return false;
  }
}

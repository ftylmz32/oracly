/// Strip patronizing stock — keep kind honesty intact.
library;

import '../../../core/personality/or_intelligent_directness.dart';

abstract final class ConversationPatronizingGuard {
  ConversationPatronizingGuard._();

  static String shape(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!OrIntelligentDirectness.looksPatronizing(trimmed)) return trimmed;
    final kept = <String>[];
    for (final part in trimmed.split(RegExp(r'(?<=[.!?])\s+'))) {
      final s = part.trim();
      if (s.isEmpty) continue;
      if (OrIntelligentDirectness.looksPatronizing(s)) continue;
      kept.add(s);
    }
    return kept.join(' ').trim();
  }
}

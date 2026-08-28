/// Picks OR reply length from message + context — preference is a ceiling.
library;

import '../../../core/personality/or_response_depth.dart';
import '../../ai/production/models/conversation_turn.dart';
import 'or_adaptive_conversation.dart';
import 'or_response_length_signals.dart';

abstract final class OrResponseLengthIntelligence {
  OrResponseLengthIntelligence._();

  /// [preference] from settings — never exceed it. Never pad upward.
  static OrResponseDepth select({
    required String userMessage,
    required OrResponseDepth preference,
    List<ConversationTurn> turns = const [],
    bool spoken = false,
  }) {
    final text = userMessage.trim();
    final pref = preference == OrResponseDepth.veryShort
        ? OrResponseDepth.short
        : preference;

    final explicit = _explicit(text);
    if (explicit != null) return _atMost(explicit, pref);

    final bias = OrAdaptiveConversation.depthBias(text, turns: turns);
    // Only lift toward deep when the turn asks for it — never inflate greetings.
    if (bias == OrResponseDepth.deep) {
      return _atMost(OrResponseDepth.deep, pref);
    }

    var score = OrResponseLengthSignals.base(text);
    score += OrResponseLengthSignals.complexity(text);
    score += OrResponseLengthSignals.emotional(text);
    score += OrResponseLengthSignals.importance(text);
    score += OrResponseLengthSignals.context(turns, text);
    if (spoken) score -= 1;

    if (score >= 3 &&
        !OrResponseLengthSignals.warrantsDeep(text, turns) &&
        _explicit(text) != OrResponseDepth.deep) {
      score = 2;
    }
    if (score < 0) score = 0;
    if (score > 3) score = 3;
    return _atMost(_fromScore(score), pref);
  }

  static OrResponseDepth? _explicit(String text) {
    final t = text.toLowerCase();
    if (_any(t, const [
      'çok kısa', 'cok kisa', 'tek cümle', 'tek cumle', 'one sentence',
      'very short',
    ])) {
      return OrResponseDepth.veryShort;
    }
    if (_any(t, const [
      'kısa tut', 'kisa tut', 'kısaca', 'kisaca', 'özetle', 'ozetle',
      'briefly', 'keep it short', 'коротко',
    ])) {
      return OrResponseDepth.short;
    }
    if (_any(t, const [
      'detaylı', 'detayli', 'ayrıntılı', 'ayrintili', 'derinlemesine',
      'uzun anlat', 'in detail', 'explain fully', 'подробно',
    ])) {
      return OrResponseDepth.deep;
    }
    return null;
  }

  static OrResponseDepth _fromScore(int score) => switch (score) {
        0 => OrResponseDepth.veryShort,
        1 => OrResponseDepth.short,
        2 => OrResponseDepth.balanced,
        _ => OrResponseDepth.deep,
      };

  static OrResponseDepth _atMost(OrResponseDepth a, OrResponseDepth ceiling) =>
      a.rank <= ceiling.rank ? a : ceiling;

  static bool _any(String hay, List<String> needles) {
    for (final n in needles) {
      if (hay.contains(n)) return true;
    }
    return false;
  }
}

/// Trailing-question hygiene — ask only when earned; no mechanical loops.
library;

abstract final class ConversationQuestionGuard {
  ConversationQuestionGuard._();

  /// Shapes the trailing sentence. Never bans phrases outright — only drops
  /// unearned or repeated mechanical probes.
  static String shape(
    String text, {
    required bool allowTrailingQuestion,
    String? priorAssistant,
  }) {
    var out = text.trim();
    out = stripMechanicalTrailing(out, priorAssistant: priorAssistant);
    return out;
  }

  static String stripAnyTrailing(String text) {
    final trimmed = text.trim();
    if (!trimmed.endsWith('?')) return trimmed;
    final parts = _sentences(trimmed);
    if (parts.length <= 1) return trimmed;
    return parts.sublist(0, parts.length - 1).join(' ').trim();
  }

  static String stripMechanicalTrailing(
    String text, {
    String? priorAssistant,
  }) {
    final trimmed = text.trim();
    if (!trimmed.endsWith('?')) return trimmed;
    final parts = _sentences(trimmed);
    if (parts.length <= 1) return trimmed;
    final last = parts.last.trim();
    if (_looksMechanical(last) ||
        _repeatsPriorProbe(last, priorAssistant)) {
      return parts.sublist(0, parts.length - 1).join(' ').trim();
    }
    return trimmed;
  }

  static bool _looksMechanical(String sentence) {
    final lower = sentence.toLowerCase();
    const hits = [
      'istersen',
      'ne düşünüyorsun',
      'nasıl hissediyorsun',
      'how do you feel',
      'how are you feeling',
      'what do you think',
      'tell me more',
      'want to tell me',
      'biraz daha anlat',
      'anlatır mısın',
      'anlatmak ister misin',
      'devam etmek ister',
      'başka ne merak',
      'nasıl yardımcı olabilirim',
      'anything else',
      'would you like to share',
      'хочешь рассказать',
      'что ты думаешь',
      'как ты себя чувствуешь',
    ];
    for (final hit in hits) {
      if (lower.contains(hit)) return true;
    }
    return false;
  }

  static bool _repeatsPriorProbe(String last, String? prior) {
    final p = (prior ?? '').trim();
    if (p.isEmpty || !p.contains('?')) return false;
    final family = _family(last);
    if (family == null) return false;
    return _family(p) == family;
  }

  static String? _family(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('istersen') || lower.contains('tell me more')) {
      return 'invite';
    }
    if (lower.contains('düşünüyorsun') || lower.contains('what do you think') ||
        lower.contains('что ты думаешь')) {
      return 'think';
    }
    if (lower.contains('hissediyorsun') ||
        lower.contains('how do you feel') ||
        lower.contains('how are you feeling') ||
        lower.contains('как ты себя чувствуешь')) {
      return 'feel';
    }
    return null;
  }

  static List<String> _sentences(String text) =>
      text.split(RegExp(r'(?<=[.!?])\s+'));
}

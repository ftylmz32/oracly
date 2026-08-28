/// Stock therapist empathy — strip scripts; keep noticed content.
library;

abstract final class ConversationEmpathyGuard {
  ConversationEmpathyGuard._();

  /// Removes mechanical empathy sentences. Does not ban warmth — only
  /// automatic validation / presence filler that replaces real noticing.
  static String shape(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final kept = <String>[];
    for (final part in _sentences(trimmed)) {
      final s = part.trim();
      if (s.isEmpty) continue;
      if (_isStockEmpathy(s)) continue;
      kept.add(_stripLeadingStockClause(s));
    }
    final joined = kept.where((s) => s.trim().isNotEmpty).join(' ').trim();
    return joined;
  }

  static bool _isStockEmpathy(String sentence) {
    final lower = sentence.toLowerCase().replaceAll(RegExp(r'[.!?…]+$'), '');
    final bare = lower.trim();
    if (_exactStock.contains(bare)) return true;
    for (final hit in _phraseHits) {
      if (bare.contains(hit)) return true;
    }
    if (_presenceOnly.hasMatch(bare)) return true;
    return false;
  }

  static String _stripLeadingStockClause(String sentence) {
    var out = sentence.trim();
    out = out.replaceFirst(_leadingStock, '');
    return out.trim();
  }

  static final _presenceOnly = RegExp(
    r"^(buradayım|yanındayım|i'?m here|i am here|я здесь|я рядом)"
    r"(,\s*acele yok)?$",
    caseSensitive: false,
  );

  static final _leadingStock = RegExp(
    r"^(seni anlıyorum|anlıyorum|buradayım|yanındayım|"
    r"i understand|i'?m here|i am here|"
    r"your feelings are valid|"
    r"that must be (so )?hard( for you)?|"
    r"i know (this|that) is (so )?hard)"
    r"[,!.]?\s+",
    caseSensitive: false,
  );

  static const _exactStock = {
    'seni anlıyorum',
    'anlıyorum',
    'buradayım',
    'yanındayım',
    "i'm here",
    'i am here',
    'i hear you',
    'я здесь',
    'я рядом',
    'я понимаю тебя',
  };

  static const _phraseHits = [
    'seni anlıyorum',
    'buradayım',
    'yanındayım',
    "i'm here",
    'i am here',
    'anlıyorum nasıl hissettiğini',
    'anlıyorum nasıl hissettiğin',
    'hislerini anlıyorum',
    'hislerinin geçerli',
    'duyguların geçerli',
    'hislerin geçerli',
    'geçerli olduğunu söylemek isterim',
    'senin için zor olduğunu',
    'bunun senin için zor',
    'üzgünüm böyle hissettiğin',
    'üzgün hissetmene üzüldüm',
    'i understand how you feel',
    "i'm sorry you're feeling",
    'i am sorry you feel',
    "i am sorry you're feeling",
    'your feelings are valid',
    'that must be hard for you',
    'i know this is hard for you',
    'i know that is hard for you',
    "i'm here for you",
    'i am here for you',
    'мне жаль, что ты так',
    'я понимаю, как ты себя чувствуешь',
    'твои чувства важны',
  ];

  static List<String> _sentences(String text) =>
      text.split(RegExp(r'(?<=[.!?])\s+'));
}

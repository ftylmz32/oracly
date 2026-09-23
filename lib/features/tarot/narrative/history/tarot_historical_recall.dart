/// Pure explicit-recall detector for historical memory (Phase 4B).
library;

import 'tarot_historical_text.dart';

abstract final class TarotHistoricalRecall {
  TarotHistoricalRecall._();

  static const _phrases = <String>{
    // TR
    'hatırla',
    'hatırlıyor',
    'hatırlıyor musun',
    'önce',
    'geçen',
    'önceki',
    'benzer',
    'benziyor',
    // EN
    'remember',
    'previous',
    'before',
    'similar',
    'last reading',
    'earlier reading',
    // RU
    'помни',
    'помнишь',
    'раньше',
    'предыдущий',
    'предыдущая',
    'предыдущее',
    'похожий',
    'похоже',
    'похожая',
  };

  /// True when [rawText] contains an explicit recall cue (token/phrase).
  static bool detects(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    final folded = TarotHistoricalText.normalizeTopic(rawText);
    if (folded == null) return false;
    // Multi-word phrases first (order by length DESC).
    final phrases = _phrases.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final p in phrases) {
      final needle = TarotHistoricalText.normalizeTopic(p)!;
      if (needle.contains(' ')) {
        if (folded.contains(needle)) return true;
      }
    }
    final tokens = TarotHistoricalText.allWordTokens(rawText);
    for (final p in phrases) {
      final needle = TarotHistoricalText.normalizeTopic(p)!;
      if (!needle.contains(' ') && tokens.contains(needle)) return true;
    }
    return false;
  }
}

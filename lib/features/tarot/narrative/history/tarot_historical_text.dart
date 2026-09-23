/// Deterministic text helpers for historical recurrence (Phase 4A / 4A.1).
library;

import 'tarot_historical_stopwords.dart';

abstract final class TarotHistoricalText {
  TarotHistoricalText._();

  /// Generic / sentinel topics that never authorize topic_match (H6).
  static const Set<String> genericTopicSentinels = {
    'general',
    'genel',
    'guidance',
    'general guidance',
    'genel rehberlik',
    'open',
    'other',
    'общий',
    'общее',
    'общая опора',
  };

  /// Stable topic equality: trim, fold Turkish I, lowercase, collapse ws.
  static String? normalizeTopic(String? raw) {
    if (raw == null) return null;
    final folded = _foldTurkishI(raw).trim().toLowerCase();
    if (folded.isEmpty) return null;
    final collapsed = folded.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.isEmpty ? null : collapsed;
  }

  /// True iff normalized topic is non-empty and not a generic sentinel.
  static bool isMeaningfulTopic(String? raw) {
    final n = normalizeTopic(raw);
    if (n == null) return false;
    return !genericTopicSentinels.contains(n);
  }

  /// Tokens length ≥4 after normalize, punctuation→space, stopword strip.
  static Set<String> tokens(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {};
    final out = <String>{};
    for (final p in _rawWordTokens(raw)) {
      if (p.length < 4) continue;
      if (TarotHistoricalStopwords.all.contains(p)) continue;
      out.add(p);
    }
    return out;
  }

  /// All letter/number word tokens after fold/lowercase (any length).
  /// Used only for reviewed short theme aliases — not kind-token overlap.
  static Set<String> allWordTokens(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {};
    return Set<String>.unmodifiable(_rawWordTokens(raw));
  }

  /// Trim, collapse whitespace, clip to [maxChars]. Empty → null.
  static String? sanitizeIntention(String? raw, {int maxChars = 120}) {
    if (raw == null) return null;
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return null;
    if (collapsed.length <= maxChars) return collapsed;
    return collapsed.substring(0, maxChars);
  }

  static List<String> _rawWordTokens(String raw) {
    final folded = _foldTurkishI(raw).toLowerCase();
    final spaced = folded.replaceAll(
      RegExp(r'[^\p{L}\p{N}]+', unicode: true),
      ' ',
    );
    return [
      for (final p in spaced.split(RegExp(r'\s+')))
        if (p.isNotEmpty) p,
    ];
  }

  static String _foldTurkishI(String s) {
    return s.replaceAll('İ', 'i').replaceAll('I', 'i').replaceAll('ı', 'i');
  }
}

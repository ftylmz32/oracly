/// Deterministic text helpers for historical recurrence (Phase 4A).
library;

import 'tarot_historical_stopwords.dart';

abstract final class TarotHistoricalText {
  TarotHistoricalText._();

  /// Stable topic equality: trim, fold Turkish I, lowercase, collapse ws.
  static String? normalizeTopic(String? raw) {
    if (raw == null) return null;
    final folded = _foldTurkishI(raw).trim().toLowerCase();
    if (folded.isEmpty) return null;
    final collapsed = folded.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.isEmpty ? null : collapsed;
  }

  /// Tokens length ≥4 after normalize, punctuation→space, stopword strip.
  static Set<String> tokens(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {};
    final folded = _foldTurkishI(raw).toLowerCase();
    final spaced = folded.replaceAll(
      RegExp(r'[^\p{L}\p{N}]+', unicode: true),
      ' ',
    );
    final parts = spaced.split(RegExp(r'\s+'));
    final out = <String>{};
    for (final p in parts) {
      if (p.length < 4) continue;
      if (TarotHistoricalStopwords.all.contains(p)) continue;
      out.add(p);
    }
    return out;
  }

  /// Trim, collapse whitespace, clip to [maxChars]. Empty → null.
  static String? sanitizeIntention(String? raw, {int maxChars = 120}) {
    if (raw == null) return null;
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return null;
    if (collapsed.length <= maxChars) return collapsed;
    return collapsed.substring(0, maxChars);
  }

  static String _foldTurkishI(String s) {
    return s.replaceAll('İ', 'i').replaceAll('I', 'i').replaceAll('ı', 'i');
  }
}

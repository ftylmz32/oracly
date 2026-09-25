/// Presentation narrative selector — primary / opening / direction (Phase 7E).
///
/// Narrative V2 compatibility: structured synthesis → [AiReadingContent.luckyEnergy].
library;

import 'ai_reading_content.dart';

class ReadingNarrativeSelection {
  const ReadingNarrativeSelection({
    required this.openingSummary,
    required this.primaryNarrative,
    required this.direction,
  });

  /// Short lead when distinct from primary; empty if omitted.
  final String openingSummary;

  /// Dominant reading body — never condensed by this selector.
  final String primaryNarrative;

  /// Closing / direction beat.
  final String direction;
}

abstract final class ReadingNarrativeSelector {
  ReadingNarrativeSelector._();

  static ReadingNarrativeSelection select(AiReadingContent content) {
    final synthesis = content.luckyEnergy.trim();
    final summary = content.generalMeaning.trim();
    final primary = synthesis.isNotEmpty ? synthesis : summary;
    final opening = _openingIfDistinct(summary: summary, primary: primary);
    final direction = content.closingMessage.trim().isNotEmpty
        ? content.closingMessage.trim()
        : content.dailyAdvice.trim();
    return ReadingNarrativeSelection(
      openingSummary: opening,
      primaryNarrative: primary,
      direction: direction,
    );
  }

  /// Deterministic duplicate guard — no NLP.
  static String _openingIfDistinct({
    required String summary,
    required String primary,
  }) {
    if (summary.isEmpty || primary.isEmpty) return '';
    final a = _norm(summary);
    final b = _norm(primary);
    if (a == b) return '';
    if (b.contains(a) && a.length >= 24) return '';
    if (a.contains(b) && b.length >= 24) return '';
    // Opening should stay short; otherwise treat as same body.
    if (summary.length > primary.length * 0.85 && summary.length > 280) {
      return '';
    }
    return summary;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

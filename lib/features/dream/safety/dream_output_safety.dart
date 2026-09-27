/// Dream Phase 3 client output firewall — defense in depth behind the
/// backend check. Scans every provider field before mapping, display or
/// storage; a violation fails the whole reading closed (no second call).
library;

import '../../ai/production/models/dream_ai_analysis.dart';
import 'dream_output_lexicon.dart';
import 'dream_safety_text.dart';

abstract final class DreamOutputSafety {
  DreamOutputSafety._();

  static List<String> fields(DreamAiAnalysis analysis) => [
        analysis.summary,
        ...analysis.symbols,
        analysis.emotionalTheme,
        analysis.interpretation,
        analysis.dailyLifeReflection,
        analysis.conclusion,
      ];

  static bool isUnsafe(DreamAiAnalysis analysis) =>
      violation(fields(analysis)) != null;

  /// The first violated check code across [texts], or null when safe.
  static String? violation(Iterable<String> texts) {
    for (final text in texts) {
      for (final segment in DreamSafetyText.segments(text)) {
        final check = _check(segment.text);
        if (check != null) return check;
      }
    }
    return null;
  }

  static String? _check(String text) {
    bool asserts(RegExp p) =>
        DreamSafetyText.hit(p, text, negationAware: true);
    if (asserts(DreamOutputLexicon.selfHarm)) return 'self_harm';
    if (asserts(DreamOutputLexicon.medical)) return 'medical_directive';
    if (asserts(DreamOutputLexicon.diagnosis)) return 'diagnosis';
    if (asserts(DreamOutputLexicon.delusion)) return 'delusion';
    if (DreamSafetyText.has(DreamOutputLexicon.traumaTerms, text) &&
        asserts(DreamOutputLexicon.blame)) {
      return 'trauma_blame';
    }
    if (asserts(DreamOutputLexicon.death)) return 'death_certainty';
    return null;
  }
}

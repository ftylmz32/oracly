/// Local dream interpretation — five grounded beats, never a plot dump.
library;

import '../models/dream.dart';
import 'dream_analysis_beats.dart';
import 'dream_analysis_facts.dart';
import 'dream_analysis_guard.dart';

abstract final class DreamInterpretationCopy {
  DreamInterpretationCopy._();

  static String dreamSummary({
    required String narrative,
    required DreamUnderstanding understanding,
  }) {
    final facts = _facts(narrative, understanding);
    return DreamAnalysisBeats.feeling(facts, _seed(facts));
  }

  static String mainInterpretation({
    required DreamUnderstanding understanding,
    String narrative = '',
    String? aiText,
  }) {
    final facts = _facts(narrative, understanding);
    return DreamAnalysisGuard.polish(aiText, facts) ??
        DreamAnalysisBeats.symbolic(facts, _seed(facts));
  }

  static String symbols(
    DreamUnderstanding understanding, {
    String narrative = '',
  }) {
    final facts = _facts(narrative, understanding);
    return DreamAnalysisBeats.detail(facts, _seed(facts));
  }

  static String emotionalMeaning(DreamUnderstanding understanding) {
    return dreamSummary(narrative: '', understanding: understanding);
  }

  static String optionalQuestion(DreamUnderstanding understanding) {
    final facts = _facts('', understanding);
    return DreamAnalysisBeats.ask(facts, _seed(facts));
  }

  static DreamAnalysisFacts _facts(
    String narrative,
    DreamUnderstanding understanding,
  ) {
    return DreamAnalysisFacts.from(
      narrative: narrative,
      understanding: understanding,
    );
  }

  static int _seed(DreamAnalysisFacts facts) =>
      Object.hash(facts.scene, facts.image).abs();
}

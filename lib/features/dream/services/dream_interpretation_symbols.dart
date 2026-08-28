/// One striking detail from the told scene — never a dictionary card.
library;

import '../models/dream.dart';
import '../models/dream_symbol.dart';
import 'dream_analysis_beats.dart';
import 'dream_analysis_facts.dart';

abstract final class DreamInterpretationSymbols {
  DreamInterpretationSymbols._();

  static String section({
    required DreamUnderstanding understanding,
    required String narrative,
  }) {
    final facts = DreamAnalysisFacts.from(
      narrative: narrative,
      understanding: understanding,
    );
    return DreamAnalysisBeats.detail(facts, Object.hash(facts.scene, facts.image).abs());
  }

  static String block({
    required DreamSymbol symbol,
    required String narrative,
  }) {
    final facts = DreamAnalysisFacts.from(
      narrative: narrative,
      understanding: DreamUnderstanding(
        symbols: [symbol],
        emotions: const [],
        locations: const [],
        relationships: const [],
        recurringElements: const [],
        summary: '',
      ),
    );
    return DreamAnalysisBeats.detail(
      facts,
      Object.hash(symbol.label, facts.scene).abs(),
    );
  }
}

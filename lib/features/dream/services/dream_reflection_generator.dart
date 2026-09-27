/// Local reflective copy — five beats, question last. Every section `local`.
library;

import '../models/dream.dart';
import '../models/dream_insight.dart';
import 'dream_analysis_composer.dart';
import 'dream_pattern_service.dart';

class DreamReflectionGenerator {
  const DreamReflectionGenerator();

  List<DreamInsight> generate({
    required Dream dream,
    required DreamUnderstanding understanding,
    required String language,
    DreamPatternMatch? pattern,
  }) {
    return DreamAnalysisComposer.compose(
      dream: dream,
      understanding: understanding,
      language: language,
      pattern: pattern,
    );
  }
}

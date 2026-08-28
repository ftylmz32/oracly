/// Local reflective copy — five beats, question last.
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
    DreamPatternMatch? pattern,
  }) {
    return DreamAnalysisComposer.compose(
      dream: dream,
      understanding: understanding,
      pattern: pattern,
    );
  }
}

/// Maps validated dream AI onto the five grounded beats.
library;

import '../../ai/production/models/dream_ai_analysis.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';
import 'dream_analysis_composer.dart';
import 'dream_pattern_service.dart';

abstract final class DreamAiInsightMapper {
  DreamAiInsightMapper._();

  static List<DreamInsight> map({
    required DreamAiAnalysis analysis,
    required Dream dream,
    required DreamUnderstanding understanding,
    DreamPatternMatch? pattern,
  }) {
    return DreamAnalysisComposer.compose(
      dream: dream,
      understanding: understanding,
      pattern: pattern,
      ai: analysis,
    );
  }
}

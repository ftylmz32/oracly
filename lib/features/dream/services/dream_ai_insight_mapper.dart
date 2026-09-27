/// Maps provider dream AI onto grounded beats with per-section provenance.
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
    required String language,
    DreamPatternMatch? pattern,
  }) {
    return DreamAnalysisComposer.compose(
      dream: dream,
      understanding: understanding,
      language: language,
      pattern: pattern,
      ai: analysis,
    );
  }
}

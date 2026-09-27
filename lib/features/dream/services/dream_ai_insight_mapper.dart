/// Maps provider dream AI onto grounded beats with per-section provenance.
library;

import '../../ai/production/models/dream_ai_analysis.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';
import 'dream_analysis_composer.dart';

abstract final class DreamAiInsightMapper {
  DreamAiInsightMapper._();

  /// [memorySummary] is the safe connected memory sent with this request
  /// (null when omitted as sensitive or absent).
  static List<DreamInsight> map({
    required DreamAiAnalysis analysis,
    required Dream dream,
    required DreamUnderstanding understanding,
    required String language,
    String? memorySummary,
  }) {
    return DreamAnalysisComposer.compose(
      dream: dream,
      understanding: understanding,
      language: language,
      ai: analysis,
      memorySummary: memorySummary,
    );
  }
}

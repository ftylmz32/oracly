/// Dream insights — live AI, dev-only local reflection, or typed error.
library;

import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_retriever.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../models/dream.dart';
import 'dream_ai_insight_mapper.dart';
import 'dream_pattern_service.dart';
import 'dream_provider_evidence.dart';
import 'dream_reading_provenance.dart';
import 'dream_reflection_generator.dart';

class DreamInsightBuilder {
  const DreamInsightBuilder({
    required this.ai,
    required this._reflection,
    this._memory,
  });

  final OraclyAiService ai;
  final DreamReflectionGenerator _reflection;
  final OraclyMemoryRetriever? _memory;

  /// [language] is the operation language captured before the request; the
  /// provider payload, guard and composition all use it.
  Future<Dream> build({
    required Dream dream,
    required DreamUnderstanding understanding,
    required String language,
    DreamPatternMatch? pattern,
  }) async {
    if (ai.isConfigured) {
      final outcome = await ai.analyzeDream(
        DreamProviderEvidence.context(
          dream: dream,
          understanding: understanding,
          language: language,
          memorySummary: _memorySummary(dream),
        ),
      );
      final insights = outcome.when(
        success: (analysis) => DreamAiInsightMapper.map(
          analysis: analysis,
          dream: dream,
          understanding: understanding,
          language: language,
          pattern: pattern,
        ),
        error: (failure) => throw AiRequestException(failure),
      );
      // Provider success alone is not AI provenance: only sections that
      // survived the guard count.
      return dream.copyWith(
        fromAi: DreamReadingProvenance.hasAcceptedAi(insights),
        insights: insights,
      );
    }
    if (ai.allowsLocalFallback) {
      return dream.copyWith(
        fromAi: false,
        insights: _reflection.generate(
          dream: dream,
          understanding: understanding,
          language: language,
          pattern: pattern,
        ),
      );
    }
    throw AiRequestException(AiFailure.noConfiguration());
  }

  String? _memorySummary(Dream dream) {
    final narrative = dream.narrative.trim();
    if (narrative.length < 8) return null;
    final query = [
      narrative,
      ...dream.selectedEmotions.map((emotion) => emotion.label),
      ...dream.tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
    ].join(' ');
    try {
      return _memory?.forInterpretation(
        query: query,
        currentType: OraclyReadingType.dream,
      );
    } catch (_) {
      // Connected memory enriches one existing call; it is never required.
      return null;
    }
  }
}

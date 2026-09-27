/// Dream insights — live AI, dev-only local reflection, or typed error.
library;

import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_retriever.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/contexts/reading_ai_context.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../models/dream.dart';
import 'dream_ai_insight_mapper.dart';
import 'dream_context_enricher.dart';
import 'dream_pattern_service.dart';
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

  Future<Dream> build({
    required Dream dream,
    required DreamUnderstanding understanding,
    DreamPatternMatch? pattern,
  }) async {
    if (ai.isConfigured) {
      final outcome = await ai.analyzeDream(
        DreamAiContext(
          narrative: DreamContextEnricher.narrativeForAi(
            narrative: dream.narrative,
            tags: dream.tags,
          ),
          symbols: understanding.symbols.map((s) => s.label).toList(),
          emotions: understanding.emotions,
          memorySummary: _memorySummary(dream),
        ),
      );
      return dream.copyWith(
        fromAi: true,
        insights: outcome.when(
          success: (analysis) => DreamAiInsightMapper.map(
            analysis: analysis,
            dream: dream,
            understanding: understanding,
            pattern: pattern,
          ),
          error: (failure) => throw AiRequestException(failure),
        ),
      );
    }
    if (ai.allowsLocalFallback) {
      return dream.copyWith(
        fromAi: false,
        insights: _reflection.generate(
          dream: dream,
          understanding: understanding,
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

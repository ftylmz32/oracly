/// Dream journey — local symbols always; live AI or typed error, never fake.
library;

import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_payload.dart';
import '../../../core/reading_version/services/reading_version_service.dart';
import '../../../core/domain/repositories/dream_repository.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/contexts/reading_ai_context.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../data/dream_record_mapper.dart';
import '../models/dream.dart';
import '../models/dream_emotion.dart';
import 'dream_ai_insight_mapper.dart';
import 'dream_context_enricher.dart';
import 'dream_pattern_service.dart';
import 'dream_reflection_generator.dart';
import 'dream_understanding_service.dart';

class DreamExperienceResult {
  const DreamExperienceResult({
    required this.dream,
    this.versionAdded = true,
  });

  final Dream dream;
  final bool versionAdded;
}

class DreamExperienceService {
  DreamExperienceService({
    required this.repository,
    required this.ai,
    DreamUnderstandingService? understandingService,
    DreamPatternService? patternService,
    DreamReflectionGenerator? reflectionGenerator,
    ReadingVersionService? versions,
  })  : _understanding = understandingService ?? DreamUnderstandingService(),
        _patterns = patternService ?? const DreamPatternService(),
        _reflection = reflectionGenerator ?? const DreamReflectionGenerator(),
        _versions = versions;

  final DreamRepository repository;
  final OraclyAiService ai;
  final DreamUnderstandingService _understanding;
  final DreamPatternService _patterns;
  final DreamReflectionGenerator _reflection;
  final ReadingVersionService? _versions;

  bool get aiAvailable => ai.isConfigured;

  Future<DreamExperienceResult> analyze({
    required String narrative,
    List<DreamEmotion> selectedEmotions = const [],
    List<String> tags = const [],
  }) {
    return _run(
      narrative: narrative,
      selectedEmotions: selectedEmotions,
      tags: tags,
    );
  }

  Future<DreamExperienceResult> reinterpret(Dream current) {
    return _run(
      narrative: current.narrative,
      selectedEmotions: current.selectedEmotions,
      tags: current.tags,
      dreamId: current.id,
      recordedAt: current.recordedAt,
    );
  }

  Future<DreamExperienceResult> _run({
    required String narrative,
    List<DreamEmotion> selectedEmotions = const [],
    List<String> tags = const [],
    String? dreamId,
    DateTime? recordedAt,
  }) async {
    final id = dreamId ?? 'dream_${DateTime.now().millisecondsSinceEpoch}';
    final at = recordedAt ?? DateTime.now();
    final understanding = _understanding.build(
      narrative: narrative,
      selectedEmotions: selectedEmotions,
    );

    var dream = Dream(
      id: id,
      narrative: narrative,
      recordedAt: at,
      tags: tags,
      selectedEmotions: selectedEmotions,
      understanding: understanding,
    );

    final priorRecords = await repository.getAll();
    final priorDreams = priorRecords
        .map(DreamRecordMapper.fromRecord)
        .where((d) => d.isAnalyzed)
        .toList();
    final pattern = _patterns.findConnection(
      current: dream,
      previousDreams: priorDreams,
    );

    if (ai.isConfigured) {
      final aiNarrative = DreamContextEnricher.narrativeForAi(
        narrative: narrative,
        tags: tags,
      );
      final outcome = await ai.analyzeDream(
        DreamAiContext(
          narrative: aiNarrative,
          symbols: understanding.symbols.map((s) => s.label).toList(),
          emotions: understanding.emotions,
        ),
      );
      dream = dream.copyWith(
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
    } else if (ai.allowsLocalFallback) {
      dream = dream.copyWith(
        fromAi: false,
        insights: _reflection.generate(
          dream: dream,
          understanding: understanding,
          pattern: pattern,
        ),
      );
    } else {
      throw AiRequestException(AiFailure.noConfiguration());
    }

    await repository.save(DreamRecordMapper.toRecord(dream));
    final analysis = DreamRecordMapper.toRecord(dream).analysis;
    final payload = ReadingVersionPayload.dream(dream, analysis);
    var versionAdded = true;
    if (_versions != null) {
      final versions = _versions;
      if (dreamId == null) {
        await versions.seedOriginal(
          rootId: id,
          kind: ReadingVersionKind.dream,
          data: payload,
        );
      } else {
        final result = await versions.tryAppendRevision(
          rootId: id,
          kind: ReadingVersionKind.dream,
          data: payload,
        );
        versionAdded = result.added;
        if (!versionAdded) {
          final prior = await repository.getById(id);
          if (prior != null) {
            return DreamExperienceResult(
              dream: DreamRecordMapper.fromRecord(prior),
              versionAdded: false,
            );
          }
        }
      }
    }
    return DreamExperienceResult(dream: dream, versionAdded: versionAdded);
  }

  Future<List<Dream>> loadHistory() async {
    final records = await repository.getAll();
    return records.map(DreamRecordMapper.fromRecord).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }
}

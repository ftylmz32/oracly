/// SPRINT-001 — Full dream analysis journey orchestrator.
library;

import '../../../core/domain/repositories/dream_repository.dart';
import '../../../features/ai/domain/models/prompts/dream_prompt.dart';
import '../../../features/ai/domain/repositories/dream_ai_repository.dart';
import '../data/dream_record_mapper.dart';
import '../models/dream.dart';
import '../models/dream_emotion.dart';
import 'dream_pattern_service.dart';
import 'dream_reflection_generator.dart';
import 'dream_understanding_service.dart';

class DreamExperienceResult {
  const DreamExperienceResult({required this.dream});

  final Dream dream;
}

class DreamExperienceService {
  DreamExperienceService({
    required DreamRepository repository,
    required DreamAIRepository aiRepository,
    DreamUnderstandingService? understandingService,
    DreamPatternService? patternService,
    DreamReflectionGenerator? reflectionGenerator,
  })  : _repository = repository,
        _aiRepository = aiRepository,
        _understanding = understandingService ?? DreamUnderstandingService(),
        _patterns = patternService ?? const DreamPatternService(),
        _reflection = reflectionGenerator ?? const DreamReflectionGenerator();

  final DreamRepository _repository;
  final DreamAIRepository _aiRepository;
  final DreamUnderstandingService _understanding;
  final DreamPatternService _patterns;
  final DreamReflectionGenerator _reflection;

  Future<DreamExperienceResult> analyze({
    required String narrative,
    List<DreamEmotion> selectedEmotions = const [],
    List<String> tags = const [],
  }) async {
    final id = 'dream_${DateTime.now().millisecondsSinceEpoch}';
    final recordedAt = DateTime.now();

    final understanding = _understanding.build(
      narrative: narrative,
      selectedEmotions: selectedEmotions,
    );

    var dream = Dream(
      id: id,
      narrative: narrative,
      recordedAt: recordedAt,
      tags: tags,
      selectedEmotions: selectedEmotions,
      understanding: understanding,
    );

    final priorRecords = await _repository.getAll();
    final priorDreams = priorRecords
        .map(DreamRecordMapper.fromRecord)
        .where((d) => d.isAnalyzed)
        .toList();

    final pattern = _patterns.findConnection(
      current: dream,
      previousDreams: priorDreams,
    );
    final connectionInsight = _patterns.buildConnectionInsight(pattern);

    String? aiText;
    try {
      final response = await _aiRepository.analyze(
        DreamPrompt(
          dreamText: narrative,
          emotions: understanding.emotions,
          symbols: understanding.symbols.map((s) => s.label).toList(),
          personality: 'reflective',
        ),
      );
      aiText = response.text;
    } catch (_) {
      aiText = null;
    }

    final insights = _reflection.generate(
      dream: dream,
      understanding: understanding,
      aiReflectionText: aiText,
      personalConnection: connectionInsight,
    );

    dream = dream.copyWith(insights: insights);

    await _repository.save(DreamRecordMapper.toRecord(dream));

    return DreamExperienceResult(dream: dream);
  }

  Future<List<Dream>> loadHistory() async {
    final records = await _repository.getAll();
    return records.map(DreamRecordMapper.fromRecord).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }
}

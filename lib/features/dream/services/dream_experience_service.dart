/// Dream journey — local symbols always; live AI or typed error, never fake.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/reading_version/services/reading_version_service.dart';
import '../../../core/domain/repositories/dream_repository.dart';
import '../../../core/memory/oracly_memory_retriever.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../data/dream_record_mapper.dart';
import '../models/dream.dart';
import '../models/dream_emotion.dart';
import '../models/dream_entry_selection.dart';
import 'dream_experience_commit.dart';
import 'dream_insight_builder.dart';
import 'dream_narrative_language.dart';
import 'dream_owner_guard.dart';
import 'dream_pattern_service.dart';
import 'dream_reflection_generator.dart';
import 'dream_understanding_service.dart';

export 'dream_experience_commit.dart' show DreamExperienceResult;

class DreamExperienceService {
  DreamExperienceService({
    required this.repository,
    required this.ai,
    required DreamOwnerGuard owner,
    DreamUnderstandingService? understandingService,
    DreamPatternService? patternService,
    DreamReflectionGenerator? reflectionGenerator,
    ReadingVersionService? versions,
    OraclyMemoryRetriever? memory,
  })  : _owner = owner,
        _understanding = understandingService ?? DreamUnderstandingService(),
        _patterns = patternService ?? const DreamPatternService(),
        _insights = DreamInsightBuilder(
          ai: ai,
          reflection: reflectionGenerator ?? const DreamReflectionGenerator(),
          memory: memory,
        ),
        _commit = DreamExperienceCommit(
          repository: repository,
          owner: owner,
          versions: versions,
        );

  final DreamRepository repository;
  final OraclyAiService ai;
  final DreamOwnerGuard _owner;
  final DreamUnderstandingService _understanding;
  final DreamPatternService _patterns;
  final DreamInsightBuilder _insights;
  final DreamExperienceCommit _commit;

  bool get aiAvailable => ai.isConfigured;

  Future<DreamExperienceResult> analyze({
    required String narrative,
    List<DreamEmotion> selectedEmotions = const [],
    List<String> tags = const [],
    DreamEntrySelection? entry,
  }) async {
    final snapshot = _captureOwner();
    return _run(
      snapshot,
      Dream(
        id: 'dream_${DateTime.now().millisecondsSinceEpoch}',
        narrative: narrative,
        recordedAt: DateTime.now(),
        tags: tags,
        entry: entry,
        selectedEmotions: selectedEmotions,
      ),
      isRevision: false,
    );
  }

  /// Re-reads [current] from the current owner's storage — an in-memory
  /// dream from a prior owner (or one already cleared) is never sent.
  Future<DreamExperienceResult> reinterpret(Dream current) async {
    final snapshot = _captureOwner();
    final stored = await repository.getById(current.id);
    if (stored == null || !_owner.stillValid(snapshot)) {
      throw const DreamOwnerChangedException();
    }
    final source = DreamRecordMapper.fromRecord(stored);
    return _run(
      snapshot,
      Dream(
        id: source.id,
        narrative: source.narrative,
        recordedAt: source.recordedAt,
        tags: source.tags,
        entry: source.entry,
        selectedEmotions: source.selectedEmotions,
      ),
      isRevision: true,
    );
  }

  /// The stored Dream for [dreamId], or null unless the same owner snapshot
  /// held across the lookup. A caller-supplied body is never evidence.
  Future<Dream?> loadOwnedDream(String dreamId) async {
    final snapshot = _owner.capture();
    if (!snapshot.isValid) return null;
    final stored = await repository.getById(dreamId);
    if (stored == null || !_owner.stillValid(snapshot)) return null;
    return DreamRecordMapper.fromRecord(stored);
  }

  DreamOwnerSnapshot _captureOwner() {
    final snapshot = _owner.capture();
    if (!snapshot.isValid) throw AiRequestException(AiFailure.authPending());
    return snapshot;
  }

  Future<DreamExperienceResult> _run(
    DreamOwnerSnapshot snapshot,
    Dream seed, {
    required bool isRevision,
  }) async {
    final language =
        DreamNarrativeLanguage.forOperation(seed.narrative, OraclyL10n.code);
    final understanding = _understanding.build(
      narrative: seed.narrative,
      selectedEmotions: seed.selectedEmotions,
      language: language,
    );
    final dream = seed.copyWith(understanding: understanding);

    final priorRecords = await repository.getAll();
    final priorDreams = priorRecords
        .map(DreamRecordMapper.fromRecord)
        .where((d) => d.isAnalyzed)
        .toList();
    final pattern = _patterns.findConnection(
      current: dream,
      previousDreams: priorDreams,
    );

    final analyzed = await _insights.build(
      dream: dream,
      understanding: understanding,
      language: language,
      pattern: pattern,
    );
    return _commit.commit(
      dream: analyzed,
      snapshot: snapshot,
      isRevision: isRevision,
    );
  }

  Future<List<Dream>> loadHistory() async {
    final records = await repository.getAll();
    return records.map(DreamRecordMapper.fromRecord).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }
}

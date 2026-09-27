/// Dream journey — local symbols always; live AI or typed error, never fake.
library;

import '../../../core/reading_version/services/reading_version_service.dart';
import '../../../core/domain/repositories/dream_repository.dart';
import '../../../core/memory/oracly_memory_retriever.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../data/dream_record_mapper.dart';
import '../history/dream_history_insight.dart';
import '../history/dream_history_reader.dart';
import '../models/dream.dart';
import '../models/dream_emotion.dart';
import '../models/dream_entry_selection.dart';
import '../safety/dream_safety_policy.dart';
import 'dream_experience_commit.dart';
import 'dream_insight_builder.dart';
import 'dream_owner_guard.dart';
import 'dream_reflection_generator.dart';
import 'dream_understanding_service.dart';

export 'dream_experience_commit.dart' show DreamExperienceResult;

class DreamExperienceService {
  DreamExperienceService({
    required this.repository,
    required this.ai,
    required DreamOwnerGuard owner,
    DreamUnderstandingService? understandingService,
    DreamReflectionGenerator? reflectionGenerator,
    ReadingVersionService? versions,
    OraclyMemoryRetriever? memory,
  })  : _owner = owner,
        _understanding = understandingService ?? DreamUnderstandingService(),
        _history = DreamHistoryReader(repository: repository, owner: owner),
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
  final DreamHistoryReader _history;
  final DreamInsightBuilder _insights;
  final DreamExperienceCommit _commit;

  bool get aiAvailable => ai.isConfigured;

  Future<DreamExperienceResult> analyze({
    required String narrative,
    List<DreamEmotion> selectedEmotions = const [],
    List<String> tags = const [],
    DreamEntrySelection? entry,
  }) async {
    DreamSafetyPolicy.ensureSafe(narrative: narrative, entry: entry, tags: tags);
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
  /// History is rebuilt from the repository as it is now.
  Future<DreamExperienceResult> reinterpret(Dream current) async {
    final snapshot = _captureOwner();
    final stored = await repository.getById(current.id);
    if (stored == null || !_owner.stillValid(snapshot)) {
      throw const DreamOwnerChangedException();
    }
    final source = DreamRecordMapper.fromRecord(stored);
    // A legacy record saved before Phase 3 is re-checked; the stored copy is
    // never mutated and no version is added.
    DreamSafetyPolicy.ensureSafe(
      narrative: source.narrative,
      entry: source.entry,
      tags: source.tags,
    );
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

  /// The stored Dream for [dreamId] (with its live recurring section), or
  /// null unless the same owner snapshot held. A caller-supplied body is
  /// never evidence.
  Future<Dream?> loadOwnedDream(String dreamId) => _history.loadOwned(dreamId);

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
    final language = DreamHistoryReader.languageOf(seed);
    final understanding = _understanding.build(
      narrative: seed.narrative,
      selectedEmotions: seed.selectedEmotions,
      language: language,
    );
    final dream = seed.copyWith(understanding: understanding);
    final history = await _history.read(
      snapshot: snapshot,
      current: dream,
      language: language,
    );
    final analyzed = await _insights.build(
      dream: dream,
      understanding: understanding,
      language: language,
      history: history,
    );
    final result = await _commit.commit(
      dream: analyzed,
      snapshot: snapshot,
      isRevision: isRevision,
    );
    return DreamExperienceResult(
      dream: DreamHistoryInsight.attach(result.dream, history, language),
      versionAdded: result.versionAdded,
    );
  }

  Future<List<Dream>> loadHistory() async {
    final records = await repository.getAll();
    return records.map(DreamRecordMapper.fromRecord).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }
}

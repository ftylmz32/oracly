/// Dream Phase 4A — reads prior-Dream history under one owner snapshot.
///
/// History comes only from `repository.getAll()` of the owner captured when
/// the operation started. The snapshot is re-checked after the read, so a
/// switch (A→B) or a round trip (A→B→A, new epoch) or a Dream clear during
/// the read discards it — the operation fails closed.
library;

import '../../../core/domain/repositories/dream_repository.dart';
import '../../../core/l10n/l10n.dart';
import '../data/dream_record_mapper.dart';
import '../models/dream.dart';
import '../services/dream_narrative_language.dart';
import '../services/dream_owner_guard.dart';
import 'dream_history_builder.dart';
import 'dream_history_evidence.dart';
import 'dream_history_insight.dart';

class DreamHistoryReader {
  const DreamHistoryReader({required this.repository, required this.owner});

  final DreamRepository repository;
  final DreamOwnerGuard owner;

  static String languageOf(Dream dream) =>
      DreamNarrativeLanguage.forOperation(dream.narrative, OraclyL10n.code);

  Future<DreamHistoryContext> read({
    required DreamOwnerSnapshot snapshot,
    required Dream current,
    required String language,
  }) async {
    if (!owner.stillValid(snapshot)) throw const DreamOwnerChangedException();
    final records = await repository.getAll();
    if (!owner.stillValid(snapshot)) throw const DreamOwnerChangedException();
    return DreamHistoryBuilder.build(
      current: current,
      saved: records.map(DreamRecordMapper.fromRecord),
      language: language,
    );
  }

  /// The stored Dream for [dreamId] with its live recurring section, or null
  /// unless the same owner snapshot held across every read.
  Future<Dream?> loadOwned(String dreamId) async {
    final snapshot = owner.capture();
    if (!snapshot.isValid) return null;
    final stored = await repository.getById(dreamId);
    if (stored == null || !owner.stillValid(snapshot)) return null;
    final dream = DreamRecordMapper.fromRecord(stored);
    if (!dream.isAnalyzed) return dream;
    final language = languageOf(dream);
    try {
      final history =
          await read(snapshot: snapshot, current: dream, language: language);
      return DreamHistoryInsight.attach(dream, history, language);
    } on DreamOwnerChangedException {
      return null;
    }
  }
}

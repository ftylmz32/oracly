/// SPRINT-001 — Dream journal source for the Reflection Engine.
library;

import '../../../core/domain/repositories/dream_repository.dart';
import '../../../core/intelligence/domain/models/reflection_entry.dart';
import '../../../core/reflection/domain/sources/reflection_source.dart';
import '../data/dream_record_mapper.dart';

class DreamReflectionSource implements ReflectionSource {
  DreamReflectionSource(this._repository);

  final DreamRepository _repository;

  @override
  ReflectionSourceKind get kind => ReflectionSourceKind.dream;

  @override
  Future<ReflectionInputPartial?> collect({required DateTime asOf}) async {
    final records = await _repository.getAll();
    if (records.isEmpty) return null;

    final reflections = <ReflectionEntry>[];
    for (final record in records) {
      final dream = DreamRecordMapper.fromRecord(record);
      final text = dream.understanding?.summary ?? record.analysis;
      if (text.trim().isEmpty) continue;
      reflections.add(
        ReflectionEntry(
          id: 'dream_ref_${record.id}',
          source: JourneyReflectionSource.dream,
          recordedAt: record.createdAt,
          text: text,
        ),
      );
    }

    if (reflections.isEmpty) return null;
    return ReflectionInputPartial(reflections: reflections);
  }
}

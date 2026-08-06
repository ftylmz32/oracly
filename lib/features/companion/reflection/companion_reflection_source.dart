/// SPRINT-003 — Companion conversations for Reflection Engine.
library;

import '../../../core/domain/repositories/ai_conversation_repository.dart';
import '../../../core/intelligence/domain/models/reflection_entry.dart';
import '../../../core/reflection/domain/sources/reflection_source.dart';
import '../data/companion_record_mapper.dart';

class CompanionReflectionSource implements ReflectionSource {
  CompanionReflectionSource(this._repository);

  final AiConversationRepository _repository;

  @override
  ReflectionSourceKind get kind => ReflectionSourceKind.companion;

  @override
  Future<ReflectionInputPartial?> collect({required DateTime asOf}) async {
    final records = await _repository.getAll();
    if (records.isEmpty) return null;

    final reflections = <ReflectionEntry>[];
    for (final record in records) {
      final conversation = CompanionRecordMapper.fromRecord(record);
      final lastAssistant = conversation.messages
          .where((m) => m.isAssistant)
          .map((m) => m.content)
          .lastOrNull;
      if (lastAssistant == null || lastAssistant.trim().isEmpty) continue;

      reflections.add(
        ReflectionEntry(
          id: 'companion_ref_${record.id}',
          source: JourneyReflectionSource.conversation,
          recordedAt: record.updatedAt,
          text: lastAssistant.length > 240
              ? '${lastAssistant.substring(0, 240)}…'
              : lastAssistant,
        ),
      );
    }

    if (reflections.isEmpty) return null;
    return ReflectionInputPartial(reflections: reflections);
  }
}

extension _LastOrNull<E> on Iterable<E> {
  E? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }
}

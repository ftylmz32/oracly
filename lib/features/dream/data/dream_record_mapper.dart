/// SPRINT-001 — Maps between [Dream] and [DreamRecord].
library;

import '../../../core/domain/models/dream_record.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';

abstract final class DreamRecordMapper {
  DreamRecordMapper._();

  static DreamRecord toRecord(Dream dream) {
    final closing = dream.insights
        .where((i) => i.kind == DreamInsightKind.closingTakeaway)
        .map((i) => i.body)
        .firstOrNull;

    return DreamRecord(
      id: dream.id,
      text: dream.narrative,
      analysis: closing ?? dream.understanding?.summary ?? '',
      createdAt: dream.recordedAt,
      updatedAt: DateTime.now(),
      emotions: dream.selectedEmotions.map((e) => e.label).toList(),
      tags: dream.tags,
      payload: dream.toJson(),
    );
  }

  static Dream fromRecord(DreamRecord record) {
    if (record.payload != null) {
      return Dream.fromJson(record.payload!);
    }
    return Dream(
      id: record.id,
      narrative: record.text,
      recordedAt: record.createdAt,
      tags: record.tags,
      selectedEmotions: const [],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

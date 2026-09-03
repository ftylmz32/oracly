/// SPRINT-001 — Maps between [Dream] and [DreamRecord].
library;

import '../../../core/domain/models/dream_record.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';

abstract final class DreamRecordMapper {
  DreamRecordMapper._();

  static DreamRecord toRecord(Dream dream) {
    final analysis = _firstBody(dream, DreamInsightKind.mainInterpretation) ??
        _firstBody(dream, DreamInsightKind.summary) ??
        _firstBody(dream, DreamInsightKind.practicalTakeaway) ??
        _firstBody(dream, DreamInsightKind.closingTakeaway) ??
        dream.understanding?.summary ??
        '';

    return DreamRecord(
      id: dream.id,
      text: dream.narrative,
      analysis: analysis,
      createdAt: dream.recordedAt,
      updatedAt: DateTime.now(),
      emotions: dream.selectedEmotions.map((e) => e.label).toList(),
      tags: dream.tags,
      payload: dream.toJson(),
    );
  }

  static String? _firstBody(Dream dream, DreamInsightKind kind) {
    for (final insight in dream.insights) {
      if (insight.kind == kind && insight.body.trim().isNotEmpty) {
        return insight.body;
      }
    }
    return null;
  }

  static Dream fromRecord(DreamRecord record) {
    final payload = record.payload;
    if (payload != null) {
      try {
        return Dream.fromJson(Map<String, dynamic>.from(payload));
      } catch (_) {
        // Corrupt/schema-drift payload must not crash history load.
      }
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

/// Normalized connected-memory records for Phase 4B pure engines.
library;

import '../evidence/narrative_memory_evidence.dart';

enum TarotConnectedMemorySourceType {
  tarot,
  coffee,
  palm,
  dream,
  soulmate,
  birthChart,
}

class TarotConnectedMemoryRecord {
  TarotConnectedMemoryRecord({
    required this.sourceId,
    required this.sourceType,
    required this.occurredAt,
    required this.summary,
    required List<String> themeIds,
    required this.confidence,
    required this.epistemic,
  }) : themeIds = List<String>.unmodifiable(themeIds);

  final String sourceId;
  final TarotConnectedMemorySourceType sourceType;
  final DateTime occurredAt;
  final String summary;
  final List<String> themeIds;
  final double confidence;
  final MemoryEvidenceEpistemic epistemic;

  String get typedSourceRef => '${sourceType.name}:$sourceId';
}

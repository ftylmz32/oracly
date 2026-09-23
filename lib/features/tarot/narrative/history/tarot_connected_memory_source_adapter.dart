/// OraclyMemoryStore → normalized connected memory (Phase 4C).
library;

import '../../../../core/memory/oracly_memory.dart';
import '../../../../core/memory/oracly_memory_store.dart';
import '../evidence/narrative_memory_evidence.dart';
import 'tarot_connected_memory_models.dart';
import 'tarot_history_card_normalize.dart';
import 'tarot_history_normalize_diagnostics.dart';
import 'tarot_live_source_index.dart';

class TarotConnectedMemorySourceAdapter {
  TarotConnectedMemorySourceAdapter({required this.memory});

  final OraclyMemoryStore memory;

  ({
    List<TarotConnectedMemoryRecord> memories,
    TarotHistoryNormalizeDiagnostics diagnostics,
  })
  load({required TarotLiveSourceIndex liveSources}) {
    final out = <TarotConnectedMemoryRecord>[];
    var skippedMissing = 0;
    var skippedMalformed = 0;

    for (final row in memory.all()) {
      if (row.kind != OraclyMemoryKind.reading) continue;
      final mapped = _mapType(row.source.type);
      if (mapped == null) continue;

      final sourceId = row.source.id.trim();
      if (sourceId.isEmpty) {
        skippedMalformed++;
        continue;
      }

      bool live;
      try {
        live = liveSources.exists(mapped, sourceId);
      } catch (_) {
        skippedMissing++;
        continue;
      }
      if (!live) {
        skippedMissing++;
        continue;
      }

      final summary = TarotHistoryCardNormalize.collapseSummary(row.summary);
      if (summary.isEmpty) {
        skippedMalformed++;
        continue;
      }

      out.add(
        TarotConnectedMemoryRecord(
          sourceId: sourceId,
          sourceType: mapped,
          occurredAt: row.source.occurredAt.toUtc(),
          summary: summary,
          themeIds: List<String>.from(row.themes),
          confidence: row.confidence.clamp(0.0, 1.0),
          epistemic: MemoryEvidenceEpistemic.interpretation,
        ),
      );
    }

    out.sort((a, b) {
      final byTime = b.occurredAt.compareTo(a.occurredAt);
      if (byTime != 0) return byTime;
      final byType = a.sourceType.name.compareTo(b.sourceType.name);
      if (byType != 0) return byType;
      return a.sourceId.compareTo(b.sourceId);
    });

    return (
      memories: List<TarotConnectedMemoryRecord>.unmodifiable(out),
      diagnostics: TarotHistoryNormalizeDiagnostics(
        skippedMissingSource: skippedMissing,
        skippedMalformed: skippedMalformed,
      ),
    );
  }

  static TarotConnectedMemorySourceType? _mapType(OraclyReadingType type) {
    return switch (type) {
      OraclyReadingType.tarot => TarotConnectedMemorySourceType.tarot,
      OraclyReadingType.coffee => TarotConnectedMemorySourceType.coffee,
      OraclyReadingType.palm => TarotConnectedMemorySourceType.palm,
      OraclyReadingType.dream => TarotConnectedMemorySourceType.dream,
      OraclyReadingType.soulmate => TarotConnectedMemorySourceType.soulmate,
      OraclyReadingType.birthChart => TarotConnectedMemorySourceType.birthChart,
      OraclyReadingType.astrology || OraclyReadingType.orConversation => null,
    };
  }
}

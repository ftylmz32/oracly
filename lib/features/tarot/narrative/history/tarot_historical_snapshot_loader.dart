/// Coordinates Phase 4C snapshot load: owner boundary + adapters.
library;

import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/data/datasources/local_storage.dart';
import '../../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../../core/domain/repositories/dream_repository.dart';
import '../../../../core/memory/oracly_memory_store.dart';
import '../../../../core/services/history_service.dart';
import '../../domain/repositories/tarot_reading_repository.dart';
import 'tarot_connected_memory_source_adapter.dart';
import 'tarot_history_source_adapter.dart';
import 'tarot_historical_models.dart';
import 'tarot_live_source_index.dart';

class TarotHistoricalSnapshotLoadResult {
  const TarotHistoricalSnapshotLoadResult({
    required this.snapshot,
    required this.privacyBlocked,
    this.skippedOwnerMismatch = 0,
    this.skippedMalformed = 0,
    this.skippedMissingSource = 0,
  });

  final TarotHistoricalSnapshot snapshot;
  final bool privacyBlocked;
  final int skippedOwnerMismatch;
  final int skippedMalformed;
  final int skippedMissingSource;
}

class TarotHistoricalSnapshotLoader {
  TarotHistoricalSnapshotLoader({
    required this.storage,
    required this.history,
    required this.tarotRepository,
    required this.memory,
    required this.dreams,
    required this.birthCharts,
  });

  final LocalStorage storage;
  final HistoryService history;
  final TarotReadingRepository tarotRepository;
  final OraclyMemoryStore memory;
  final DreamRepository dreams;
  final BirthChartRepository birthCharts;

  Future<TarotHistoricalSnapshotLoadResult> load({
    required String? currentOwnerId,
  }) async {
    final localOwnerId = storage.getString(UserLocalDataIsolation.ownerKey);
    if (!_ownerBoundaryOk(currentOwnerId, localOwnerId)) {
      return TarotHistoricalSnapshotLoadResult(
        snapshot: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: const [],
        ),
        privacyBlocked: true,
      );
    }

    final historyResult = await TarotHistorySourceAdapter(
      history: history,
      tarotRepository: tarotRepository,
    ).load(currentOwnerId: currentOwnerId);

    final live = await TarotLiveSourceIndex.build(
      storage: storage,
      history: history,
      tarotRepository: tarotRepository,
      dreams: dreams,
      birthCharts: birthCharts,
    );

    final memoryResult = TarotConnectedMemorySourceAdapter(
      memory: memory,
    ).load(liveSources: live);

    final diag = historyResult.diagnostics + memoryResult.diagnostics;
    return TarotHistoricalSnapshotLoadResult(
      snapshot: TarotHistoricalSnapshot(
        tarotReadings: historyResult.readings,
        connectedMemories: memoryResult.memories,
      ),
      privacyBlocked: false,
      skippedOwnerMismatch: diag.skippedOwnerMismatch,
      skippedMalformed: diag.skippedMalformed,
      skippedMissingSource: diag.skippedMissingSource,
    );
  }

  static bool _ownerBoundaryOk(String? current, String? local) {
    if (current != null) return local == current;
    return local == null;
  }
}

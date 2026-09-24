/// Phase 6F — history snapshot loader provider for Narrative live path.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../data/repositories/tarot_reading_repository_impl.dart';
import '../narrative/history/tarot_historical_snapshot_loader.dart';

final tarotHistoricalSnapshotLoaderProvider =
    Provider<TarotHistoricalSnapshotLoader>((ref) {
  final storage = ref.watch(localStorageProvider);
  return TarotHistoricalSnapshotLoader(
    storage: storage,
    history: ref.watch(historyServiceProvider),
    tarotRepository: TarotReadingRepositoryImpl.fromStorage(storage),
    memory: ref.watch(oraclyMemoryStoreProvider),
    dreams: ref.watch(dreamRepositoryProvider),
    birthCharts: ref.watch(birthChartRepositoryProvider),
  );
});

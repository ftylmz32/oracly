/// OR-1150 — Content layer Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/backend_providers.dart';
import '../astrology/repositories/astrology_content_repository.dart';
import '../daily_energy/repositories/daily_energy_content_repository.dart';
import '../dream/repositories/dream_content_repository.dart';
import '../oracle/repositories/oracle_content_repository.dart';
import '../shared/cache/content_cache.dart';
import '../shared/data/local_content_favorites_store.dart';
import '../shared/services/content_favorites_store.dart';
import '../tarot/repositories/tarot_content_repository.dart';

final contentCacheProvider = Provider<ContentCacheLayer>((ref) {
  return InMemoryContentCache();
});

final contentFavoritesStoreProvider = Provider<ContentFavoritesStore>((ref) {
  return LocalContentFavoritesStore(ref.watch(localStorageProvider));
});

final tarotContentRepositoryProvider = Provider<TarotContentRepository>((ref) {
  return MockTarotContentRepository(
    favoritesStore: ref.watch(contentFavoritesStoreProvider),
    cacheLayer: ref.watch(contentCacheProvider),
  );
});

final dreamContentRepositoryProvider = Provider<DreamContentRepository>((ref) {
  return MockDreamContentRepository(
    favoritesStore: ref.watch(contentFavoritesStoreProvider),
  );
});

final dailyEnergyContentRepositoryProvider =
    Provider<DailyEnergyContentRepository>((ref) {
  return MockDailyEnergyContentRepository(
    favoritesStore: ref.watch(contentFavoritesStoreProvider),
  );
});

final astrologyContentRepositoryProvider =
    Provider<AstrologyContentRepository>((ref) {
  return MockAstrologyContentRepository(
    favoritesStore: ref.watch(contentFavoritesStoreProvider),
  );
});

final oracleContentRepositoryProvider = Provider<OracleContentRepository>((ref) {
  return MockOracleContentRepository(
    favoritesStore: ref.watch(contentFavoritesStoreProvider),
  );
});

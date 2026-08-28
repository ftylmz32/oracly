/// Privacy Control Center — real clear/reset actions only.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/intelligence/services/personal_memory_service.dart';
import '../../../core/services/history_service.dart';
import '../../../features/favorite_moments/services/favorite_moments_service.dart';
import '../../../services/memory_service.dart';
import 'privacy_discovery_clear.dart';

class PrivacyControlService {
  PrivacyControlService({
    required HistoryService history,
    required FavoriteMomentsService favorites,
    required PersonalMemoryService personalMemory,
    required BirthChartRepository birthCharts,
    required LocalStorage storage,
    MemoryService? legacyMemory,
  })  : _history = history,
        _favorites = favorites,
        _personalMemory = personalMemory,
        _birthCharts = birthCharts,
        _storage = storage,
        _legacyMemory = legacyMemory ?? MemoryService();

  final HistoryService _history;
  final FavoriteMomentsService _favorites;
  final PersonalMemoryService _personalMemory;
  final BirthChartRepository _birthCharts;
  final LocalStorage _storage;
  final MemoryService _legacyMemory;

  Future<void> clearDiscoveryHistory() => PrivacyDiscoveryClear.run(
        storage: _storage,
        history: _history,
        birthCharts: _birthCharts,
      );

  Future<void> clearFavorites() async {
    await _favorites.clearAll();
    for (final domain in const [
      'tarot',
      'dream',
      'astrology',
      'daily_energy',
      'oracle',
    ]) {
      await _storage.remove('content_favorites_$domain');
    }
    for (final key in _storage.keys
        .where((k) => k.startsWith('content_favorites_'))
        .toList()) {
      await _storage.remove(key);
    }
  }

  Future<void> resetMemorySummary() async {
    await _personalMemory.userReset();
    await _legacyMemory.clearMemory();
  }
}

/// Clears all discovery-history sources — journal stays derived.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/services/history_service.dart';
import '../../../features/coffee/data/coffee_reading_store.dart';
import '../../../features/palm/data/palm_reading_store.dart';

abstract final class PrivacyDiscoveryClear {
  PrivacyDiscoveryClear._();

  static Future<void> run({
    required LocalStorage storage,
    required HistoryService history,
    required BirthChartRepository birthCharts,
  }) async {
    await history.clear();
    await storage.setStringList('dream_records', const []);
    await storage.setStringList(CoffeeReadingStore.key, const []);
    await storage.setStringList(PalmReadingStore.key, const []);
    await storage.setStringList('astrology_history', const []);
    await storage.setStringList('ai_conversations', const []);
    await birthCharts.clearLatest();
  }
}

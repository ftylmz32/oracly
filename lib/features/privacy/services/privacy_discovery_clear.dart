/// Clears all discovery-history sources — journal stays derived.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/services/history_service.dart';
import '../../../features/coffee/data/coffee_reading_store.dart';
import '../../../features/palm/data/palm_reading_store.dart';
import '../../../features/tarot/data/datasources/tarot_local_datasource.dart';
import 'discovery_owned_image_wipe.dart';

abstract final class PrivacyDiscoveryClear {
  PrivacyDiscoveryClear._();

  static Future<void> run({
    required LocalStorage storage,
    required HistoryService history,
    required BirthChartRepository birthCharts,
  }) async {
    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);
    await history.clear();
    await storage.setStringList('dream_records', const []);
    await storage.setStringList(CoffeeReadingStore.key, const []);
    await storage.setStringList(PalmReadingStore.key, const []);
    await storage.setStringList('astrology_history', const []);
    await storage.setStringList('ai_conversations', const []);
    await storage.setStringList(TarotLocalDataSource.historyKey, const []);
    await storage.remove(TarotLocalDataSource.activeKey);
    await birthCharts.clearLatest();
  }
}

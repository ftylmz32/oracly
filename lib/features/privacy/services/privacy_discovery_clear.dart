/// Clears all discovery-history sources — journal stays derived.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../../../core/services/history_service.dart';
import '../../../features/coffee/data/coffee_reading_store.dart';
import '../../../features/palm/data/palm_reading_store.dart';
import '../../../features/tarot/data/datasources/tarot_local_datasource.dart';
import 'discovery_owned_image_wipe.dart';
import 'privacy_dream_clear.dart';

abstract final class PrivacyDiscoveryClear {
  PrivacyDiscoveryClear._();

  static Future<void> run({
    required LocalStorage storage,
    required HistoryService history,
    required BirthChartRepository birthCharts,
  }) async {
    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);

    final memory = OraclyMemoryStore(storage);
    await _purgeCoffeeSources(storage, memory);
    await _purgePalmSources(storage, memory);
    final dreamDurable = await PrivacyDreamClear.run(storage, memory);

    // Malformed/unparseable legacy rows survive typed delete — force empty.
    await storage.setStringList('dream_records', const []);
    await storage.setStringList(CoffeeReadingStore.key, const []);
    await storage.setStringList(PalmReadingStore.key, const []);

    await history.clear();
    await storage.setStringList('astrology_history', const []);
    await storage.setStringList('ai_conversations', const []);
    await storage.setStringList(TarotLocalDataSource.historyKey, const []);
    await storage.remove(TarotLocalDataSource.activeKey);
    String? birthChartSourceId;
    try {
      birthChartSourceId = (await birthCharts.getLatest())?.id;
    } catch (_) {}
    await birthCharts.clearLatest();
    if (birthChartSourceId != null) {
      try {
        await memory.removeBySourceAndType(
          birthChartSourceId,
          OraclyReadingType.birthChart,
        );
      } catch (_) {
        // Clearing the source remains authoritative when the index is damaged.
      }
    }

    // Orphan connected-memory type purge after authoritative sources cleared.
    // SoulMate survives Discovery clear by product contract — do not purge.
    for (final type in const [
      OraclyReadingType.tarot,
      OraclyReadingType.coffee,
      OraclyReadingType.palm,
      OraclyReadingType.dream,
      OraclyReadingType.birthChart,
    ]) {
      try {
        await memory.removeByType(type);
      } catch (_) {}
    }

    // Every other source was still attempted above; never report success
    // while Dream narrative text may survive.
    if (!dreamDurable) {
      throw StateError('dream discovery clear incomplete');
    }
  }

  static Future<void> _purgeCoffeeSources(
    LocalStorage storage,
    OraclyMemoryStore memory,
  ) async {
    final store = CoffeeReadingStore(storage, memory: memory);
    for (final id in store.all().map((e) => e.id).toList()) {
      try {
        await store.delete(id);
      } catch (_) {}
    }
  }

  static Future<void> _purgePalmSources(
    LocalStorage storage,
    OraclyMemoryStore memory,
  ) async {
    final store = PalmReadingStore(storage, memory: memory);
    for (final id in store.all().map((e) => e.id).toList()) {
      try {
        await store.delete(id);
      } catch (_) {}
    }
  }
}

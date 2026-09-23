/// Live local source existence index for Phase 4C connected-memory firewall.
library;

import '../../../../core/data/datasources/local_storage.dart';
import '../../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../../core/domain/repositories/dream_repository.dart';
import '../../../birth_chart/data/birth_chart_record_mapper.dart';
import '../../../birth_chart/services/birth_chart_persistence_validator.dart';
import '../../../coffee/data/coffee_reading_store.dart';
import '../../../palm/data/palm_reading_store.dart';
import '../../../premium/data/soul_mate_result_store.dart';
import 'tarot_connected_memory_models.dart';

class TarotLiveSourceIndex {
  const TarotLiveSourceIndex({
    required this.tarotIds,
    required this.coffeeIds,
    required this.palmIds,
    required this.dreamIds,
    required this.soulmateAuthoritativeId,
    required this.journeyReadyBirthChartId,
  });

  final Set<String> tarotIds;
  final Set<String> coffeeIds;
  final Set<String> palmIds;
  final Set<String> dreamIds;
  final String? soulmateAuthoritativeId;
  final String? journeyReadyBirthChartId;

  bool exists(TarotConnectedMemorySourceType type, String sourceId) {
    final id = sourceId.trim();
    if (id.isEmpty) return false;
    return switch (type) {
      TarotConnectedMemorySourceType.tarot => tarotIds.contains(id),
      TarotConnectedMemorySourceType.coffee => coffeeIds.contains(id),
      TarotConnectedMemorySourceType.palm => palmIds.contains(id),
      TarotConnectedMemorySourceType.dream => dreamIds.contains(id),
      TarotConnectedMemorySourceType.soulmate => soulmateAuthoritativeId == id,
      TarotConnectedMemorySourceType.birthChart =>
        journeyReadyBirthChartId == id,
    };
  }

  /// [tarotIds] must come from accepted TarotHistorySourceAdapter rows only.
  static Future<TarotLiveSourceIndex> build({
    required LocalStorage storage,
    required Set<String> tarotIds,
    required DreamRepository dreams,
    required BirthChartRepository birthCharts,
  }) async {
    String? soulmateId;
    try {
      final meta = await SoulMateResultStore.readMeta(storage);
      if (meta != null && meta.hasAuthoritativeInterpretation) {
        soulmateId = meta.id.trim();
        if (soulmateId.isEmpty) soulmateId = null;
      }
    } catch (_) {
      soulmateId = null;
    }

    String? birthId;
    try {
      final record = await birthCharts.getLatest();
      if (record != null) {
        final chart = BirthChartRecordMapper.fromRecord(record);
        if (BirthChartPersistenceValidator.isJourneyReady(chart)) {
          birthId = record.id.trim();
          if (birthId.isEmpty) birthId = null;
        }
      }
    } catch (_) {
      birthId = null;
    }

    final dreamIds = <String>{};
    try {
      for (final d in await dreams.getAll()) {
        if (d.id.trim().isNotEmpty) dreamIds.add(d.id.trim());
      }
    } catch (_) {}

    return TarotLiveSourceIndex(
      tarotIds: Set<String>.unmodifiable(tarotIds),
      coffeeIds: Set<String>.unmodifiable({
        for (final c in CoffeeReadingStore(storage).all())
          if (c.id.trim().isNotEmpty) c.id.trim(),
      }),
      palmIds: Set<String>.unmodifiable({
        for (final p in PalmReadingStore(storage).all())
          if (p.id.trim().isNotEmpty) p.id.trim(),
      }),
      dreamIds: Set<String>.unmodifiable(dreamIds),
      soulmateAuthoritativeId: soulmateId,
      journeyReadyBirthChartId: birthId,
    );
  }
}

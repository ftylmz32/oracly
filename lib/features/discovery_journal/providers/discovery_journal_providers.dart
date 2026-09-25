/// Loads Keşif Günlüğü from existing repositories only.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../coffee/providers/coffee_providers.dart';
import '../../daily_message/data/daily_return_store.dart';
import '../../favorite_moments/providers/favorite_moments_providers.dart';
import '../../palm/providers/palm_providers.dart';
import '../../premium/providers/soul_mate_saved_provider.dart';
import '../../star_map/artifacts/yildizname_artifact.dart';
import '../../star_map/artifacts/yildizname_artifact_exceptions.dart';
import '../../star_map/artifacts/yildizname_artifact_providers.dart';
import '../models/discovery_journal_entry.dart';
import '../services/discovery_journal_aggregator.dart';
import '../services/discovery_journal_saved.dart';

final discoveryJournalEntriesProvider =
    FutureProvider<List<DiscoveryJournalEntry>>((ref) async {
  final readings = await ref.watch(historyServiceProvider).getAll();
  final dreams = await ref.watch(dreamRepositoryProvider).getAll();
  final conversations =
      await ref.watch(aiConversationRepositoryProvider).getAll();
  final coffee = ref.watch(coffeeReadingStoreProvider).all();
  final palm = ref.watch(palmReadingStoreProvider).all();
  final astrology = await ref.watch(astrologyRepositoryProvider).getHistory();
  final starChart = await _safeBirthChart(ref);
  final starMapArtifacts = await _safeArtifacts(ref);
  final daily = DailyReturnStore(ref.watch(localStorageProvider)).snapshots(
    DateTime.now(),
  );
  final favorites =
      ref.watch(favoriteMomentsProvider).valueOrNull ?? const [];
  final soulMate = await _soulMate(ref);
  final merged = DiscoveryJournalAggregator.merge(
    readings: readings,
    dreams: dreams,
    coffee: coffee,
    conversations: conversations,
    palm: palm,
    astrology: astrology,
    starChart: starChart,
    starMapArtifacts: starMapArtifacts,
    daily: daily,
    soulMate: soulMate,
  );
  return DiscoveryJournalSaved.mark(merged, favorites);
});

Future<dynamic> _soulMate(Ref ref) async {
  try {
    final loaded =
        await ref.watch(soulMateResultServiceProvider).latestWithPortrait();
    return loaded?.meta;
  } catch (_) {
    return null;
  }
}

Future<dynamic> _safeBirthChart(Ref ref) async {
  try {
    return await ref.watch(birthChartRepositoryProvider).getLatest();
  } catch (_) {
    return null;
  }
}

Future<List<YildiznameArtifact>> _safeArtifacts(Ref ref) async {
  try {
    return await ref.watch(yildiznameArtifactRepositoryProvider).getAll();
  } on YildiznameArtifactOwnerUnavailableException {
    return const [];
  } catch (_) {
    return const [];
  }
}

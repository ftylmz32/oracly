/// Loads discovery profile + surface memory from canonical stores only.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../birth_chart/providers/birth_information_provider.dart';
import '../../coffee/providers/coffee_providers.dart';
import '../../daily_message/data/daily_return_store.dart';
import '../../palm/providers/palm_providers.dart';
import '../data/daily_personal_observation_store.dart';
import '../data/discovery_surface_memory.dart';
import '../models/discovery_recommendation.dart';
import '../models/oracly_observation.dart';
import '../models/personal_discovery_profile.dart';
import '../models/personal_discovery_sources.dart';
import '../models/personal_insight.dart';
import '../models/surfaced_theme_record.dart';
import '../services/daily_personal_observation_service.dart';
import '../services/discovery_recommendation_engine.dart';
import '../services/personal_discovery_profile_builder.dart';
import '../services/personal_insight_service.dart';

final discoverySurfaceMemoryProvider = Provider<DiscoverySurfaceMemory>((ref) {
  return DiscoverySurfaceMemory(ref.watch(localStorageProvider));
});

final personalDiscoveryProfileProvider =
    FutureProvider<PersonalDiscoveryProfile>((ref) async {
  final birth = await ref.watch(birthInformationProvider.future);
  final settings = await ref.watch(settingsServiceProvider).load();
  final readings = await ref.watch(historyServiceProvider).getAll();
  final dreams = await ref.watch(dreamRepositoryProvider).getAll();
  final conversations =
      await ref.watch(aiConversationRepositoryProvider).getAll();
  final coffee = ref.watch(coffeeReadingStoreProvider).all();
  final palm = ref.watch(palmReadingStoreProvider).all();
  final astrology = await ref.watch(astrologyRepositoryProvider).getHistory();
  final starChart = await ref.watch(birthChartRepositoryProvider).getLatest();
  final daily = DailyReturnStore(ref.watch(localStorageProvider)).snapshots(
    DateTime.now(),
  );
  final profile = PersonalDiscoveryProfileBuilder.from(
    PersonalDiscoverySources(
      birth: birth,
      settings: settings,
      readings: readings,
      dreams: dreams,
      coffee: coffee,
      conversations: conversations,
      astrology: astrology,
      starChart: starChart,
      dailyMessages: daily,
      palm: palm,
    ),
  );
  String? name;
  try {
    final profileName = (await ref.read(userRepositoryProvider).getProfile())
        .name
        .trim();
    name = profileName.isEmpty ? null : profileName;
  } catch (_) {
    name = null;
  }
  await ref.read(personalMemoryServiceProvider).reconcile(
        profile,
        preferredName: name,
      );
  return profile;
});

final discoveryRecommendationProvider = Provider<DiscoveryRecommendation>((ref) {
  final profile = ref.watch(personalDiscoveryProfileProvider).valueOrNull ??
      PersonalDiscoveryProfile.empty;
  return DiscoveryRecommendationEngine.decide(profile);
});

final dailyPersonalObservationStoreProvider =
    Provider<DailyPersonalObservationStore>((ref) {
  return DailyPersonalObservationStore(ref.watch(localStorageProvider));
});

final oraclyObservationProvider = Provider.family<OraclyObservation?, String>(
  (ref, surface) {
    final profile = ref.watch(personalDiscoveryProfileProvider).valueOrNull;
    if (profile == null) return null;
    final recent = ref.watch(discoverySurfaceMemoryProvider).all();
    return DailyPersonalObservationService.resolve(
      profile,
      store: ref.watch(dailyPersonalObservationStoreProvider),
      recent: recent,
      surface: surface,
    );
  },
);

List<PersonalInsight> discoveryInsightsFor(
  PersonalDiscoveryProfile profile,
  List<SurfacedThemeRecord> recent, {
  required String surface,
  DateTime? day,
}) {
  return PersonalInsightService.fromProfile(
    profile,
    day: day,
    recent: recent,
    surface: surface,
  );
}

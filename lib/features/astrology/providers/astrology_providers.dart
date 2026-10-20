/// Astrology feature providers — preferences + sign resolver.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/backend_providers.dart'
    show localDataOwnerEpochProvider;
import '../../ai/production/oracly_ai_providers.dart';
import '../../ai/production/oracly_astrology_daily_ai_service.dart';
import '../../birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import '../../birth_chart/providers/birth_information_provider.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../data/astrology_preferences_store.dart';
import '../models/astrology_daily_reading.dart';
import '../services/astrology_sign_resolver.dart';
import '../sky/astrology_natal_sky.dart';
import '../sky/astrology_personal_reading_service.dart';

final astrologyPreferencesStoreProvider =
    Provider<AstrologyPreferencesStore>((ref) {
  return AstrologyPreferencesStore(ref.watch(localStorageProvider));
});

final astrologySignResolverProvider = Provider<AstrologySignResolver>((ref) {
  return AstrologySignResolver(
    preferences: ref.watch(astrologyPreferencesStoreProvider),
    birthCharts: ref.watch(birthChartRepositoryProvider),
  );
});

/// The signed-in owner's natal points, or null without saved birth data.
/// Rebuilt with the birth chart store, so it follows an account switch.
final astrologyNatalSkyProvider =
    FutureProvider<AstrologyNatalSky?>((ref) async {
  final profile = await ref.watch(birthInformationProvider.future);
  if (profile == null) return null;
  final evidence = await ref.watch(savedNatalEvidenceProvider.future);
  return AstrologyNatalSky.from(
    profile: profile,
    evidence: evidence,
    ephemeris: AstrologyEphemeris.shared,
  );
});

/// Today's personal reading for the owner's own sign, keyed by local day
/// (`yyyy-mm-dd`) so midnight starts a new one. Null means: show the general
/// sign reading, labelled as general (offline, no birth data, other locale,
/// writer unavailable, or a refused text).
final astrologyPersonalReadingProvider =
    FutureProvider.family<AstrologyDailyReading?, String>((ref, dayKey) async {
  ref.watch(localDataOwnerEpochProvider);
  if (OraclyL10n.code != 'tr') return null;
  final natal = await ref.watch(astrologyNatalSkyProvider.future);
  if (natal == null) return null;
  final ai = ref.watch(oraclyAiServiceProvider);
  final storage = ref.watch(localStorageProvider);
  String? name;
  try {
    name = (await ref.read(userProfileProvider.future)).name;
  } catch (_) {}
  List<String> themes = const [];
  try {
    themes = (await ref.read(personalDiscoveryProfileProvider.future))
        .observedRecurringLabels;
  } catch (_) {}
  final service = AstrologyPersonalReadingService(
    storage: storage,
    ownerId: () => storage.getString(UserLocalDataIsolation.ownerKey),
    ephemeris: AstrologyEphemeris.shared,
    ai: ai is OraclyAstrologyDailyAiService
        ? ai as OraclyAstrologyDailyAiService
        : null,
  );
  final parts = dayKey.split('-').map(int.parse).toList();
  return service.load(
    natal: natal,
    day: DateTime(parts[0], parts[1], parts[2]),
    themes: themes,
    addressName: name,
  );
});

/// Local calendar day key for [astrologyPersonalReadingProvider].
String astrologyDayKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

abstract final class AstrologyEphemeris {
  AstrologyEphemeris._();

  static final shared = AstronomiaEphemerisAdapter();
}

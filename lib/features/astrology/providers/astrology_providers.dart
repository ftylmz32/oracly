/// Astrology feature providers — preferences + sign resolver.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import '../../birth_chart/providers/birth_information_provider.dart';
import '../data/astrology_preferences_store.dart';
import '../services/astrology_sign_resolver.dart';
import '../sky/astrology_natal_sky.dart';

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

abstract final class AstrologyEphemeris {
  AstrologyEphemeris._();

  static final shared = AstronomiaEphemerisAdapter();
}

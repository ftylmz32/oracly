/// Astrology feature providers — preferences + sign resolver.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../data/astrology_preferences_store.dart';
import '../services/astrology_sign_resolver.dart';

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

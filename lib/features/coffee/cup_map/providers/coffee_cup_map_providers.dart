/// Fincan Haritası providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../services/coffee_cup_map_consent.dart';
import '../services/coffee_cup_map_store.dart';

/// `null` where no local storage is bound (the map then simply never
/// appears; the reading itself is unaffected).
final coffeeCupMapStoreProvider = Provider<CoffeeCupMapStore?>((ref) {
  try {
    return CoffeeCupMapStore(ref.watch(localStorageProvider));
  } catch (_) {
    return null;
  }
});

/// `null` where no local storage is bound (no choice is offered and no
/// photo is kept).
final coffeeCupMapConsentProvider = Provider<CoffeeCupMapConsent?>((ref) {
  try {
    return CoffeeCupMapConsent(ref.watch(localStorageProvider));
  } catch (_) {
    return null;
  }
});

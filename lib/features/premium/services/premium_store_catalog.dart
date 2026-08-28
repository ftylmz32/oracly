/// Canonical Play / App Store product IDs for ORACLY Premium.
///
/// Create these in Google Play Console / App Store Connect before the store
/// port can report isConfigured. Do not invent UI prices — the store supplies
/// price labels after a successful product query.
library;

import '../../../core/domain/models/premium_plan.dart';

abstract final class PremiumStoreCatalog {
  PremiumStoreCatalog._();

  static const monthlyId = 'app.oracly.premium.monthly';
  static const yearlyId = 'app.oracly.premium.yearly';
  static const lifetimeId = 'app.oracly.premium.lifetime';

  static const Set<String> allIds = {monthlyId, yearlyId, lifetimeId};

  static String idFor(PremiumPlanKind kind) => switch (kind) {
        PremiumPlanKind.monthly => monthlyId,
        PremiumPlanKind.yearly => yearlyId,
        PremiumPlanKind.lifetime => lifetimeId,
      };

  static PremiumPlanKind? kindFor(String productId) {
    final id = productId.trim();
    if (id == monthlyId) return PremiumPlanKind.monthly;
    if (id == yearlyId) return PremiumPlanKind.yearly;
    if (id == lifetimeId) return PremiumPlanKind.lifetime;
    return null;
  }

  static bool isSubscription(PremiumPlanKind kind) =>
      kind == PremiumPlanKind.monthly || kind == PremiumPlanKind.yearly;
}
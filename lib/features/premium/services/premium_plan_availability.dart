/// Platform-aware Premium plan visibility / purchase eligibility.
///
/// Shared catalog still includes lifetime for Android. iOS App Store Connect
/// ships monthly + yearly only — never expose or purchase lifetime there.
library;

import 'package:flutter/foundation.dart';

import '../../../core/domain/models/premium_plan.dart';
import 'premium_store_catalog.dart';

abstract final class PremiumPlanAvailability {
  PremiumPlanAvailability._();

  static bool isPurchasable(PremiumPlanKind kind, {TargetPlatform? platform}) {
    final p = platform ?? defaultTargetPlatform;
    if (p == TargetPlatform.iOS && kind == PremiumPlanKind.lifetime) {
      return false;
    }
    return true;
  }

  static List<PremiumPlanModel> visiblePlans(
    List<PremiumPlanModel> plans, {
    TargetPlatform? platform,
  }) {
    return [
      for (final plan in plans)
        if (isPurchasable(plan.kind, platform: platform)) plan,
    ];
  }

  /// Prefer yearly when a stale/non-purchasable selection must be corrected.
  static PremiumPlanKind normalizeSelection(
    PremiumPlanKind selected, {
    TargetPlatform? platform,
  }) {
    if (isPurchasable(selected, platform: platform)) return selected;
    return PremiumPlanKind.yearly;
  }

  /// Product IDs to query from the store for this platform.
  static Set<String> storeQueryIds({TargetPlatform? platform}) {
    final p = platform ?? defaultTargetPlatform;
    if (p == TargetPlatform.iOS) {
      return {PremiumStoreCatalog.monthlyId, PremiumStoreCatalog.yearlyId};
    }
    return PremiumStoreCatalog.allIds;
  }
}

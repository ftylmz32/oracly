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

  /// iOS: only plans the store actually returned may be offered — never a
  /// pending-price placeholder. Other platforms keep [visiblePlans].
  static List<PremiumPlanModel> offeredPlans(
    List<PremiumPlanModel> plans, {
    required bool Function(PremiumPlanKind kind) storeReturned,
    TargetPlatform? platform,
  }) {
    final p = platform ?? defaultTargetPlatform;
    final visible = visiblePlans(plans, platform: p);
    if (p != TargetPlatform.iOS) return visible;
    return [
      for (final plan in visible)
        if (storeReturned(plan.kind)) plan,
    ];
  }

  /// Whether [kind] may be selected / purchased given the offered [plans].
  static bool isOffered(
    PremiumPlanKind kind,
    List<PremiumPlanModel> plans, {
    TargetPlatform? platform,
  }) {
    final p = platform ?? defaultTargetPlatform;
    if (!isPurchasable(kind, platform: p)) return false;
    if (p != TargetPlatform.iOS) return true;
    return plans.any((plan) => plan.kind == kind);
  }

  /// Keeps [current] when offered; otherwise yearly only if yearly is
  /// offered, else the first offered plan.
  static PremiumPlanKind preferredSelection(
    PremiumPlanKind current,
    List<PremiumPlanModel> plans, {
    TargetPlatform? platform,
  }) {
    if (plans.isEmpty) return normalizeSelection(current, platform: platform);
    if (isOffered(current, plans, platform: platform)) return current;
    if (isOffered(PremiumPlanKind.yearly, plans, platform: platform)) {
      return PremiumPlanKind.yearly;
    }
    for (final plan in plans) {
      if (isOffered(plan.kind, plans, platform: platform)) return plan.kind;
    }
    return normalizeSelection(current, platform: platform);
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

/// Authoritative Premium feature gate matrix — one place, no screen-local rules.
library;

import '../../../core/modules/oracly_feature_id.dart';

/// What Premium unlocks today. Free rituals stay free.
enum PremiumGatedCapability {
  orFullConversation,
  orVoice,
  soulMateGeneration,
  journeyArchive,
  journeyThemeHistory,
  orJourneyContext,
}

abstract final class PremiumFeatureGates {
  PremiumFeatureGates._();

  /// Registry modules that must call [PremiumAccess] before open.
  static const Set<OraclyFeatureId> navigationPremiumModules = {
    OraclyFeatureId.soulMate,
  };

  /// Capabilities that require commerce entitlement [active].
  static const Set<PremiumGatedCapability> entitlementCapabilities = {
    PremiumGatedCapability.orFullConversation,
    PremiumGatedCapability.orVoice,
    PremiumGatedCapability.soulMateGeneration,
    PremiumGatedCapability.journeyArchive,
    PremiumGatedCapability.journeyThemeHistory,
    PremiumGatedCapability.orJourneyContext,
  };

  /// Free users may enter the chamber (preview). Compose/mic stay locked.
  static bool orChamberPreviewAllowedWhenFree = true;

  /// Tarot, Coffee, Palm, Astrology, Yildizname, Daily, Journal stay free.
  static bool ritualRequiresPremium(OraclyFeatureId id) {
    return navigationPremiumModules.contains(id);
  }

  static bool capabilityRequiresPremium(PremiumGatedCapability cap) =>
      entitlementCapabilities.contains(cap);
}

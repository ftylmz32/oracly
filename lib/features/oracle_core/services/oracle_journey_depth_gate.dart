/// Resolves Premium journey depth without hiding free basics.
library;

import '../models/oracle_journey_depth_access.dart';
import '../models/oracle_premium_opportunity.dart';

abstract final class OracleJourneyDepthGate {
  OracleJourneyDepthGate._();

  static OracleJourneyDepthAccess resolve({
    required OraclePremiumOpportunity opportunity,
    required bool hasEvidence,
    required bool isPremium,
    bool journeyReady = false,
  }) {
    if (!hasEvidence && !journeyReady) {
      return const OracleJourneyDepthAccess(
        allowBasicNextAction: false,
        allowBasicObservation: false,
        allowSoftPremiumInvite: false,
        allowDeepOrContext: false,
        allowThemeHistory: false,
        allowJourneyArchive: false,
        allowFullCrossFeature: false,
      );
    }

    final deepReady =
        opportunity == OraclePremiumOpportunity.journeyDepth || journeyReady;

    if (isPremium) {
      return OracleJourneyDepthAccess(
        allowBasicNextAction: hasEvidence,
        allowBasicObservation: true,
        allowSoftPremiumInvite: false,
        allowDeepOrContext: deepReady,
        allowThemeHistory: deepReady,
        allowJourneyArchive: deepReady,
        allowFullCrossFeature: deepReady,
      );
    }

    return OracleJourneyDepthAccess(
      allowBasicNextAction: hasEvidence,
      allowBasicObservation: true,
      allowSoftPremiumInvite: deepReady,
      allowDeepOrContext: false,
      allowThemeHistory: false,
      allowJourneyArchive: false,
      allowFullCrossFeature: false,
    );
  }
}

/// Oracle Core MVP - at most one evidence-backed NextAction.
library;

import '../../personal_discovery/models/cross_discovery_insight.dart';
import '../../personal_discovery/models/discovery_recommended_feature.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../data/oracle_next_action_memory.dart';
import '../models/oracle_next_action.dart';
import '../models/oracle_next_action_reason.dart';
import '../models/oracle_premium_opportunity.dart';
import 'oracle_next_action_eligibility.dart';
import 'oracle_next_action_evidence.dart';

abstract final class OracleNextActionEngine {
  OracleNextActionEngine._();

  static const ttl = Duration(days: 2);
  static const journeyDepthSources = 3;
  static const journeyDepthCount = 4;

  /// Returns 0 or 1 NextAction. Never invents themes.
  static OracleNextAction? decide(
    PersonalDiscoveryProfile profile, {
    OracleNextActionMemory? memory,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final target = DiscoveryRecommendedFeature.companion;
    if (!OracleNextActionEligibility.featureAllowed(
      target,
      profile.sourceActivity,
      clock,
    )) {
      return null;
    }

    final ranked = [
      for (final insight in profile.crossInsights)
        if (OracleNextActionEligibility.insightQualifies(insight, clock))
          insight,
    ]..sort(_compare);

    for (final insight in ranked) {
      final evidence = OracleNextActionEvidence.idsForTheme(
        profile.observations,
        insight.theme,
      );
      final sources = OracleNextActionEvidence.sourcesForTheme(
        profile.observations,
        insight.theme,
      );
      if (evidence.length < OracleNextActionEligibility.minOccurrences) {
        continue;
      }
      if (sources.length < OracleNextActionEligibility.minSourceFeatures) {
        continue;
      }
      if (memory != null &&
          memory.isBlocked(
            theme: insight.theme,
            feature: target,
            now: clock,
          )) {
        continue;
      }
      return _build(
        insight: insight,
        evidenceIds: evidence,
        sourceFeatures: sources,
        clock: clock,
        feature: target,
      );
    }
    return null;
  }

  static OracleNextAction _build({
    required CrossDiscoveryInsight insight,
    required List<String> evidenceIds,
    required List<String> sourceFeatures,
    required DateTime clock,
    required DiscoveryRecommendedFeature feature,
  }) {
    final day =
        '${clock.year.toString().padLeft(4, '0')}-'
        '${clock.month.toString().padLeft(2, '0')}-'
        '${clock.day.toString().padLeft(2, '0')}';
    return OracleNextAction(
      nextActionId: 'oracle_na|${insight.theme}|${feature.name}|$day',
      recommendedFeature: feature,
      reasonType: OracleNextActionReason.reflectWithOr,
      theme: insight.theme,
      evidenceIds: List.unmodifiable(evidenceIds),
      sourceFeatures: List.unmodifiable(sourceFeatures),
      generatedAt: clock,
      expiresAt: clock.add(ttl),
      premiumOpportunity: _premium(insight),
      occurrenceCount: insight.discoveryCount,
    );
  }

  static OraclePremiumOpportunity _premium(CrossDiscoveryInsight insight) {
    if (insight.sourceCount >= journeyDepthSources &&
        insight.discoveryCount >= journeyDepthCount) {
      return OraclePremiumOpportunity.journeyDepth;
    }
    return OraclePremiumOpportunity.none;
  }

  static int _compare(CrossDiscoveryInsight a, CrossDiscoveryInsight b) {
    final recency = b.lastObserved.compareTo(a.lastObserved);
    if (recency != 0) return recency;
    final count = b.discoveryCount.compareTo(a.discoveryCount);
    if (count != 0) return count;
    final sources = b.sourceCount.compareTo(a.sourceCount);
    if (sources != 0) return sources;
    return a.theme.compareTo(b.theme);
  }
}

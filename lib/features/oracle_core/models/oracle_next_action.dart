/// At most one calm NextAction - evidence-backed, never inventing.
library;

import '../../personal_discovery/models/discovery_recommended_feature.dart';
import 'oracle_next_action_reason.dart';
import 'oracle_premium_opportunity.dart';

class OracleNextAction {
  const OracleNextAction({
    required this.nextActionId,
    required this.recommendedFeature,
    required this.reasonType,
    required this.theme,
    required this.evidenceIds,
    required this.sourceFeatures,
    required this.generatedAt,
    required this.expiresAt,
    required this.premiumOpportunity,
    this.occurrenceCount = 0,
  });

  final String nextActionId;
  final DiscoveryRecommendedFeature recommendedFeature;
  final OracleNextActionReason reasonType;
  final String theme;
  final List<String> evidenceIds;
  final List<String> sourceFeatures;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final OraclePremiumOpportunity premiumOpportunity;
  final int occurrenceCount;

  bool get hasEvidence => evidenceIds.isNotEmpty && sourceFeatures.length >= 2;
}

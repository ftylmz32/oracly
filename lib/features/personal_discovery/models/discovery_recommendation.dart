/// One primary suggestion. No score field — UI never shows ranking.
library;

import 'discovery_recommend_kind.dart';
import 'discovery_recommended_feature.dart';

class DiscoveryRecommendation {
  const DiscoveryRecommendation({
    required this.feature,
    required this.kind,
    this.theme,
    this.source,
    this.recurring = false,
    this.evidenceCount = 0,
  });

  final DiscoveryRecommendedFeature feature;
  final DiscoveryRecommendKind kind;
  final String? theme;
  final String? source;
  final bool recurring;

  /// Windowed record count behind a source reason. 0 for themes / empty.
  final int evidenceCount;

  bool get hasEvidence => kind != DiscoveryRecommendKind.empty;

  static const empty = DiscoveryRecommendation(
    feature: DiscoveryRecommendedFeature.dailyMessage,
    kind: DiscoveryRecommendKind.empty,
  );
}

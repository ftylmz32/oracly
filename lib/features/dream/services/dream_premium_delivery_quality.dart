/// Configured AI delivery contract — one centralized check after mapping.
///
/// A provider "success" is only a premium reading when every required
/// section survived the client guard as provider prose. Anything less is a
/// typed invalid response: never silently completed with local text, never
/// persisted, never retried. [DreamInsightKind.themes] and
/// [DreamInsightKind.recurringPattern] are local by design and not required.
library;

import '../models/dream_insight.dart';

abstract final class DreamPremiumDeliveryQuality {
  DreamPremiumDeliveryQuality._();

  static const required = <DreamInsightKind>[
    DreamInsightKind.summary,
    DreamInsightKind.emotionalMeaning,
    DreamInsightKind.mainInterpretation,
    DreamInsightKind.personalConnection,
    DreamInsightKind.closingTakeaway,
  ];

  /// The first required section that is missing, empty or not accepted AI;
  /// null when the delivery is complete.
  static DreamInsightKind? firstGap(List<DreamInsight> insights) {
    for (final kind in required) {
      final section = insights.where((i) => i.kind == kind).firstOrNull;
      if (section == null ||
          section.body.trim().isEmpty ||
          section.source != DreamInsightSource.ai) {
        return kind;
      }
    }
    return null;
  }

  static bool accepts(List<DreamInsight> insights) => firstGap(insights) == null;
}

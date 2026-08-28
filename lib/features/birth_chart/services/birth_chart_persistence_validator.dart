/// Validates persisted birth chart payloads before resuming a journey.
library;

import '../models/birth_chart.dart';

abstract final class BirthChartPersistenceValidator {
  BirthChartPersistenceValidator._();

  static bool isJourneyReady(BirthChart chart) {
    if (chart.insights.isEmpty) return false;

    for (final insight in chart.insights) {
      if (insight.title.trim().isEmpty || insight.body.trim().isEmpty) {
        return false;
      }
    }

    return true;
  }
}

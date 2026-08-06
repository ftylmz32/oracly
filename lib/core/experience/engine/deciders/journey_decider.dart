/// RC-011 — Journey and ritual highlight decisions.
library;

import '../../../universe/oracly_ritual_time.dart';
import '../../domain/models/experience_feature_flags.dart';
import '../../domain/models/experience_orchestrator_input.dart';
import '../../domain/models/journey_context.dart';

abstract final class JourneyDecider {
  JourneyDecider._();

  static JourneyContext decide(ExperienceOrchestratorInput input) {
    final ritualEngaged = input.ritualToday.hasEngaged;
    final highlightRitual = _shouldHighlightRitual(input, ritualEngaged);

    return JourneyContext(
      hasJourneyMemory: input.hasJourneyMemory,
      highlightTodaysRitual: highlightRitual,
      ritualCompletedToday: ritualEngaged,
      totalReadings: input.totalReadings,
      hasRecurringPatterns: input.hasRecurringPatterns,
    );
  }

  static bool _shouldHighlightRitual(
    ExperienceOrchestratorInput input,
    bool ritualEngaged,
  ) {
    if (ritualEngaged) return false;
    if (!(input.featureFlags[ExperienceFeatureFlags.dailyRitual] ?? true)) {
      return false;
    }

    return switch (input.ritualTime) {
      OraclyRitualTime.morning ||
      OraclyRitualTime.evening =>
        true,
      OraclyRitualTime.afternoon ||
      OraclyRitualTime.night =>
        input.totalReadings == 0,
    };
  }
}

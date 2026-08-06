/// RC-011 — Greeting style decisions.
library;

import '../../../universe/oracly_ritual_time.dart';
import '../../domain/models/experience_orchestrator_input.dart';
import '../../domain/models/greeting_context.dart';

abstract final class GreetingDecider {
  GreetingDecider._();

  static GreetingContext decide(ExperienceOrchestratorInput input) {
    if (input.totalReadings == 0) {
      return const GreetingContext(
        tone: GreetingTone.newJourney,
        styleKey: 'greeting_new_journey',
        personalizeWithJourney: false,
      );
    }

    final tone = _toneFromRitualTime(input.ritualTime);
    final returning = !input.ritualToday.hasEngaged;

    return GreetingContext(
      tone: returning ? GreetingTone.returning : tone,
      styleKey: returning
          ? 'greeting_returning_${input.ritualTime.name}'
          : 'greeting_${input.ritualTime.name}',
      personalizeWithJourney: input.hasJourneyMemory,
    );
  }

  static GreetingTone _toneFromRitualTime(OraclyRitualTime time) =>
      switch (time) {
        OraclyRitualTime.morning => GreetingTone.morning,
        OraclyRitualTime.afternoon => GreetingTone.afternoon,
        OraclyRitualTime.evening => GreetingTone.evening,
        OraclyRitualTime.night => GreetingTone.night,
      };
}

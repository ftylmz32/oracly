/// RC-011 — Extensible signal providers for future modules.
library;

import '../../../../features/daily_ritual/models/daily_ritual_day.dart';

enum ExperienceSignalKind {
  readings,
  ritual,
  preferences,
  session,
  ai,
  featureFlags,
  dream,
  astrology,
  numerology,
  moonRitual,
}

/// Future modules contribute partial signals without modifying the orchestrator.
abstract class ExperienceSignalProvider {
  ExperienceSignalKind get kind;

  Future<ExperienceSignalPartial?> collect({required DateTime asOf});
}

class ExperienceSignalPartial {
  const ExperienceSignalPartial({
    this.ritualToday,
    this.premiumActive,
    this.aiAvailable,
    this.sessionDuration,
    this.featureFlags = const {},
  });

  final DailyRitualDay? ritualToday;
  final bool? premiumActive;
  final bool? aiAvailable;
  final Duration? sessionDuration;
  final Map<String, bool> featureFlags;

  ExperienceSignalPartial merge(ExperienceSignalPartial other) {
    return ExperienceSignalPartial(
      ritualToday: other.ritualToday ?? ritualToday,
      premiumActive: other.premiumActive ?? premiumActive,
      aiAvailable: other.aiAvailable ?? aiAvailable,
      sessionDuration: other.sessionDuration ?? sessionDuration,
      featureFlags: {...featureFlags, ...other.featureFlags},
    );
  }
}

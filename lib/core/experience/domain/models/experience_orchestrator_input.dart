/// RC-011 — Signals consumed by the experience orchestrator.
library;

import '../../../../features/daily_ritual/models/daily_ritual_day.dart';
import '../../../../features/premium/models/personalization_models.dart';
import '../../../reflection/domain/models/reflection_summary.dart';
import '../../../universe/oracly_ritual_time.dart';

class ExperienceOrchestratorInput {
  const ExperienceOrchestratorInput({
    required this.asOf,
    required this.ritualTime,
    required this.reflectionSummary,
    required this.ritualToday,
    required this.settings,
    required this.premiumActive,
    required this.aiAvailable,
    required this.featureFlags,
    required this.totalReadings,
    required this.reflectionCount,
    this.sessionDuration,
  });

  final DateTime asOf;
  final OraclyRitualTime ritualTime;
  final ReflectionSummary reflectionSummary;
  final DailyRitualDay ritualToday;
  final PersonalizationSettings settings;
  final bool premiumActive;
  final bool aiAvailable;
  final Duration? sessionDuration;
  final Map<String, bool> featureFlags;
  final int totalReadings;
  final int reflectionCount;

  bool get hasJourneyMemory =>
      totalReadings > 0 || reflectionSummary.hasObservablePatterns;

  bool get hasRecurringPatterns =>
      reflectionSummary.recurringThemes.isNotEmpty;
}

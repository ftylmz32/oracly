/// RC-011 — Experience orchestrator facade — gathers signals, returns recommendations.
library;

import '../../reflection/services/reflection_engine_service.dart';
import '../../universe/oracly_universe_state.dart';
import '../domain/models/experience_feature_flags.dart';
import '../domain/models/experience_context.dart';
import '../domain/models/experience_orchestrator_input.dart';
import '../domain/signals/experience_signal_provider.dart';
import '../engine/experience_orchestrator.dart';
import '../../../features/daily_ritual/services/daily_ritual_service.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../services/premium_service.dart';
import '../../services/settings_service.dart';

/// Screens request an [ExperienceContext] — they never contain business decisions.
class ExperienceOrchestratorService {
  ExperienceOrchestratorService({
    required ReflectionEngineService reflection,
    required DailyRitualService dailyRitual,
    required SettingsService settings,
    required PremiumService premium,
    ExperienceOrchestrator orchestrator = const ExperienceOrchestrator(),
    List<ExperienceSignalProvider> signalProviders = const [],
    bool aiAvailable = true,
  })  : _reflection = reflection,
        _dailyRitual = dailyRitual,
        _settings = settings,
        _premium = premium,
        _orchestrator = orchestrator,
        _signalProviders = signalProviders,
        _aiAvailable = aiAvailable;

  final ReflectionEngineService _reflection;
  final DailyRitualService _dailyRitual;
  final SettingsService _settings;
  final PremiumService _premium;
  final ExperienceOrchestrator _orchestrator;
  final List<ExperienceSignalProvider> _signalProviders;
  final bool _aiAvailable;

  Future<ExperienceContext> decide({
    DateTime? asOf,
    Duration? sessionDuration,
    PersonalizationSettings? settingsOverride,
  }) async {
    final moment = asOf ?? DateTime.now();
    final input = await _buildInput(
      asOf: moment,
      sessionDuration: sessionDuration,
      settingsOverride: settingsOverride,
    );
    return _orchestrator.decide(input);
  }

  ExperienceContext decideFromInput(ExperienceOrchestratorInput input) =>
      _orchestrator.decide(input);

  Future<ExperienceOrchestratorInput> buildInput({
    DateTime? asOf,
    Duration? sessionDuration,
    PersonalizationSettings? settingsOverride,
  }) =>
      _buildInput(
        asOf: asOf ?? DateTime.now(),
        sessionDuration: sessionDuration,
        settingsOverride: settingsOverride,
      );

  Future<ExperienceOrchestratorInput> _buildInput({
    required DateTime asOf,
    Duration? sessionDuration,
    PersonalizationSettings? settingsOverride,
  }) async {
    final universe = OraclyUniverseState.current(asOf);
    final reflectionSummary = await _reflection.analyze(asOf: asOf);
    final readings = await _reflection.buildInput(asOf: asOf);
    final reflections = readings.reflections;

    var ritualToday = _dailyRitual.loadToday(asOf);
    var premiumActive = await _premium.isActive();
    var aiAvailable = _aiAvailable;
    var flags = ExperienceFeatureFlags.defaults(aiAvailable: aiAvailable);
    var resolvedSession = sessionDuration;

    for (final provider in _signalProviders) {
      final partial = await provider.collect(asOf: asOf);
      if (partial == null) continue;
      if (partial.ritualToday != null) ritualToday = partial.ritualToday!;
      if (partial.premiumActive != null) premiumActive = partial.premiumActive!;
      if (partial.aiAvailable != null) aiAvailable = partial.aiAvailable!;
      if (partial.sessionDuration != null) {
        resolvedSession = partial.sessionDuration;
      }
      flags = {...flags, ...partial.featureFlags};
    }

    final settings = settingsOverride ?? await _settings.load();

    return ExperienceOrchestratorInput(
      asOf: asOf,
      ritualTime: universe.ritualTime,
      reflectionSummary: reflectionSummary,
      ritualToday: ritualToday,
      settings: settings,
      premiumActive: premiumActive,
      aiAvailable: aiAvailable,
      sessionDuration: resolvedSession,
      featureFlags: flags,
      totalReadings: readings.readings.length,
      reflectionCount: reflections.length,
    );
  }
}

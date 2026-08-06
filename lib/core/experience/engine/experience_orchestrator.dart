/// RC-011 — Central experience decision layer — coordinates, never implements UI.
library;

import '../domain/models/experience_context.dart';
import '../domain/models/experience_orchestrator_input.dart';
import 'deciders/greeting_decider.dart';
import 'deciders/journey_decider.dart';
import 'deciders/recommendation_decider.dart';
import 'deciders/reflection_decider.dart';

class ExperienceOrchestrator {
  const ExperienceOrchestrator();

  ExperienceContext decide(ExperienceOrchestratorInput input) {
    return ExperienceContext(
      generatedAt: input.asOf,
      schemaVersion: ExperienceContext.currentSchemaVersion,
      greeting: GreetingDecider.decide(input),
      reflection: ReflectionDecider.decide(input),
      journey: JourneyDecider.decide(input),
      recommendations: RecommendationDecider.decide(input),
    );
  }
}

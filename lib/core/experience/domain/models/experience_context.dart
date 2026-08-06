/// RC-011 — Root experience recommendation — UI maps keys to presentation.
library;

import 'greeting_context.dart';
import 'journey_context.dart';
import 'recommendation_context.dart';
import 'reflection_context.dart';

class ExperienceContext {
  const ExperienceContext({
    required this.generatedAt,
    required this.schemaVersion,
    required this.greeting,
    required this.reflection,
    required this.journey,
    required this.recommendations,
  });

  static const int currentSchemaVersion = 1;

  final DateTime generatedAt;
  final int schemaVersion;
  final GreetingContext greeting;
  final ReflectionContext reflection;
  final JourneyContext journey;
  final RecommendationContext recommendations;
}

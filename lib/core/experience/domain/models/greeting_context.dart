/// RC-011 — Greeting tone recommendation.
library;

enum GreetingTone {
  morning,
  afternoon,
  evening,
  night,
  returning,
  newJourney,
}

/// Immutable greeting recommendation — UI maps styleKey to copy.
class GreetingContext {
  const GreetingContext({
    required this.tone,
    required this.styleKey,
    required this.personalizeWithJourney,
  });

  final GreetingTone tone;
  final String styleKey;
  final bool personalizeWithJourney;
}

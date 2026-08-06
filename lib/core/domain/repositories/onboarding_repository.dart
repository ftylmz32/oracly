/// OR-1120 — Onboarding completion persistence contract.
library;

abstract class OnboardingRepository {
  Future<bool> isCompleted();

  Future<void> markCompleted();
}

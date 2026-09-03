/// Completes onboarding in a fixed order — marker last, steps idempotent.
library;

/// Runs required first-launch writes, then marks onboarding complete last.
abstract final class OnboardingCompletion {
  OnboardingCompletion._();

  /// Ordered steps. Throws on first failure so the completion marker is never
  /// written after a partial setup.
  static Future<void> run({
    required Future<void> Function() persistProfile,
    required Future<void> Function() requestFirstReading,
    required Future<void> Function() grantStarterGems,
    required Future<void> Function() clearDraft,
    required Future<void> Function() markCompleted,
    List<String>? stepLog,
  }) async {
    await persistProfile();
    stepLog?.add('profile');
    await requestFirstReading();
    stepLog?.add('first_reading');
    await grantStarterGems();
    stepLog?.add('gems');
    await clearDraft();
    stepLog?.add('draft');
    await markCompleted();
    stepLog?.add('complete');
  }
}

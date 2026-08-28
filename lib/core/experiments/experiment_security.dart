/// Blocks financial and unsafe experiment ids — no billing A/B without review.
library;

abstract final class ExperimentSecurity {
  ExperimentSecurity._();

  static const liveMode = 'live';

  static final blockedId = RegExp(
    r'billing|premium|gem|purchase|price|payment|subscription|store|checkout',
    caseSensitive: false,
  );

  static bool isAllowed(String experimentId) => !blockedId.hasMatch(experimentId);
}

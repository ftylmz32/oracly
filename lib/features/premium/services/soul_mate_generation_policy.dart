/// Soulmate wait and retry contract — one logical generation, no extra job queue.
library;

import '../../ai/production/ai_failure.dart';
import '../../ai/production/soulmate_client_timeout.dart';

enum SoulMateGenerationPhase {
  idle,
  validating,
  submitting,
  generating,
  succeeded,
  failedRecoverable,
  failedFinal,
}

enum SoulMateFailureKind { temporary, connection, input, unavailable }

abstract final class SoulMateGenerationPolicy {
  SoulMateGenerationPolicy._();

  /// One automatic follow-up after a fast transient failure. Not a loop.
  static const maxAttempts = 2;

  /// Stay under the observed Cloud Run ceiling (180s) with a small margin.
  static const clientWaitCeiling = Duration(seconds: 175);

  /// Client must still be listening when the image abort returns.
  static const imageAbortGrace = Duration(seconds: 15);

  /// A full image wait must not be automatically repeated — Cloud Run is 180s.
  static const autoRetryOnlyIfFasterThan = Duration(seconds: 30);

  static Duration clientWait(Duration imageTimeout) =>
      SoulmateClientTimeout.wait(imageTimeout);

  static bool shouldAutoRetry({
    required AiFailureKind kind,
    required int completedAttempts,
    required Duration elapsed,
  }) {
    if (completedAttempts >= maxAttempts) return false;
    if (completedAttempts < 1) return false;
    if (elapsed >= autoRetryOnlyIfFasterThan) return false;
    return kind == AiFailureKind.network ||
        kind == AiFailureKind.providerError ||
        kind == AiFailureKind.timeout ||
        kind == AiFailureKind.authPending;
  }

  static bool isDeterministic(AiFailureKind kind) {
    return kind == AiFailureKind.noConfiguration ||
        kind == AiFailureKind.unauthorized ||
        kind == AiFailureKind.appCheck ||
        kind == AiFailureKind.invalidResponse ||
        kind == AiFailureKind.imageAnalysisUnavailable;
  }

  static SoulMateFailureKind failureKindFor(AiFailureKind kind) {
    return switch (kind) {
      AiFailureKind.network => SoulMateFailureKind.connection,
      AiFailureKind.invalidResponse ||
      AiFailureKind.imageAnalysisUnavailable =>
        SoulMateFailureKind.input,
      AiFailureKind.noConfiguration ||
      AiFailureKind.unauthorized ||
      AiFailureKind.appCheck =>
        SoulMateFailureKind.unavailable,
      _ => SoulMateFailureKind.temporary,
    };
  }
}

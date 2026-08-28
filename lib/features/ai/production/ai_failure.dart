/// Typed AI failures — Turkish user copy, never raw provider text.
library;

import '../../../core/copy/resilience_copy.dart';
import '../../coffee/copy/coffee_copy.dart';

enum AiFailureKind {
  noConfiguration,
  unauthorized,
  network,
  timeout,
  rateLimit,
  invalidResponse,
  providerError,
  imageAnalysisUnavailable,
}

class AiFailure {
  const AiFailure(this.kind, this.userMessage);

  final AiFailureKind kind;
  final String userMessage;

  factory AiFailure.noConfiguration() => AiFailure(
        AiFailureKind.noConfiguration,
        ResilienceCopy.aiConfigMissing,
      );

  /// Auth rejected by proxy (401/403) — not missing dart-define config.
  factory AiFailure.unauthorized() => AiFailure(
        AiFailureKind.unauthorized,
        ResilienceCopy.aiUnauthorized,
      );

  /// Reachability failure (proxy/socket) — not the same as "device offline".
  factory AiFailure.network() => AiFailure(
        AiFailureKind.network,
        ResilienceCopy.aiUnavailable,
      );

  factory AiFailure.timeout() => AiFailure(
        AiFailureKind.timeout,
        ResilienceCopy.slowResponse,
      );

  factory AiFailure.rateLimit() => AiFailure(
        AiFailureKind.rateLimit,
        ResilienceCopy.aiRateLimited,
      );

  factory AiFailure.invalidResponse() => AiFailure(
        AiFailureKind.invalidResponse,
        ResilienceCopy.aiEmptyResponse,
      );

  factory AiFailure.providerError() => AiFailure(
        AiFailureKind.providerError,
        ResilienceCopy.aiUnavailable,
      );

  factory AiFailure.imageAnalysisUnavailable() => AiFailure(
        AiFailureKind.imageAnalysisUnavailable,
        CoffeeCopy.analysisUnavailable,
      );

  factory AiFailure.invalidImage([String? message]) => AiFailure(
        AiFailureKind.invalidResponse,
        message ?? CoffeeCopy.imageUnclear,
      );

  @override
  String toString() => 'AiFailure($kind)';
}

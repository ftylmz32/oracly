/// Typed AI failures — Turkish user copy, never raw provider text.
library;

import '../../../core/copy/resilience_copy.dart';
import '../../coffee/copy/coffee_copy.dart';
import '../../palm/copy/palm_copy.dart';
import '../../premium/copy/soul_mate_copy.dart';

enum AiFailureKind {
  noConfiguration,
  unauthorized,
  authPending,
  appCheck,
  network,
  timeout,
  rateLimit,
  invalidResponse,
  providerError,
  imageAnalysisUnavailable,

  /// Valid provider reply exists; only local persistence failed.
  localPersistence,
}

enum AiAnalysisFeature { coffee, palm, soulmate }

class AiFailure {
  const AiFailure(this.kind, this.userMessage);

  final AiFailureKind kind;
  final String userMessage;

  factory AiFailure.noConfiguration() =>
      AiFailure(AiFailureKind.noConfiguration, ResilienceCopy.aiConfigMissing);

  /// Auth rejected by proxy (401/403) — not missing dart-define config.
  factory AiFailure.unauthorized() =>
      AiFailure(AiFailureKind.unauthorized, ResilienceCopy.aiUnauthorized);

  /// Firebase session still bootstrapping — retryable, not permanent.
  factory AiFailure.authPending() =>
      AiFailure(AiFailureKind.authPending, ResilienceCopy.aiAuthPending);

  /// App Check attestation missing/failed — distinguishable from user auth.
  factory AiFailure.appCheck() =>
      AiFailure(AiFailureKind.appCheck, ResilienceCopy.aiAppCheck);

  /// Reachability failure (proxy/socket) — not the same as "device offline".
  factory AiFailure.network() =>
      AiFailure(AiFailureKind.network, ResilienceCopy.aiUnavailable);

  factory AiFailure.timeout() =>
      AiFailure(AiFailureKind.timeout, ResilienceCopy.slowResponse);

  factory AiFailure.rateLimit() =>
      AiFailure(AiFailureKind.rateLimit, ResilienceCopy.aiRateLimited);

  factory AiFailure.invalidResponse() =>
      AiFailure(AiFailureKind.invalidResponse, ResilienceCopy.aiEmptyResponse);

  factory AiFailure.providerError() =>
      AiFailure(AiFailureKind.providerError, ResilienceCopy.aiUnavailable);

  factory AiFailure.localPersistence([String? message]) => AiFailure(
    AiFailureKind.localPersistence,
    message ?? ResilienceCopy.temporaryFailure,
  );

  factory AiFailure.imageAnalysisUnavailable({AiAnalysisFeature? feature}) =>
      AiFailure(AiFailureKind.imageAnalysisUnavailable, switch (feature) {
        AiAnalysisFeature.palm => PalmCopy.analysisUnavailable,
        AiAnalysisFeature.soulmate => SoulMateCopy.unavailable,
        AiAnalysisFeature.coffee || null => CoffeeCopy.analysisUnavailable,
      });

  factory AiFailure.invalidImage([String? message]) => AiFailure(
    AiFailureKind.invalidResponse,
    message ?? CoffeeCopy.imageUnclear,
  );

  static AiFailure relabelImageAnalysis(
    AiFailure failure,
    AiAnalysisFeature feature,
  ) {
    if (failure.kind == AiFailureKind.imageAnalysisUnavailable) {
      return AiFailure.imageAnalysisUnavailable(feature: feature);
    }
    return failure;
  }

  @override
  String toString() => 'AiFailure($kind)';
}

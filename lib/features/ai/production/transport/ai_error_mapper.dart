/// Map HTTP / proxy error codes to typed [AiFailure] — never raw bodies.
library;

import '../ai_failure.dart';

abstract final class AiErrorMapper {
  AiErrorMapper._();

  static AiFailure fromStatus(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return AiFailure.unauthorized();
    }
    if (statusCode == 408) return AiFailure.timeout();
    if (statusCode == 429) return AiFailure.rateLimit();
    if (statusCode >= 500) return AiFailure.providerError();
    return AiFailure.providerError();
  }

  static AiFailure fromCode(String? code) {
    return switch ((code ?? '').trim().toLowerCase()) {
      'no_configuration' => AiFailure.noConfiguration(),
      'unauthorized' || 'forbidden' => AiFailure.unauthorized(),
      'network' || 'network_error' => AiFailure.network(),
      'timeout' => AiFailure.timeout(),
      'rate_limit' || 'rate_limited' => AiFailure.rateLimit(),
      'invalid_response' => AiFailure.invalidResponse(),
      'invalid_request' ||
      'validation_error' =>
        AiFailure.invalidImage(),
      'vision_unavailable' ||
      'image_unavailable' ||
      'image_analysis_unavailable' =>
        AiFailure.imageAnalysisUnavailable(),
      'internal_error' || 'provider_error' => AiFailure.providerError(),
      _ => AiFailure.providerError(),
    };
  }
}

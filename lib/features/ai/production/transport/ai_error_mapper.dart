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
      'unauthorized' ||
      'forbidden' ||
      'authentication_required' =>
        AiFailure.unauthorized(),
      'app_check_required' || 'app_check' => AiFailure.appCheck(),
      'network' || 'network_error' => AiFailure.network(),
      'timeout' || 'provider_timeout' => AiFailure.timeout(),
      'rate_limit' || 'rate_limited' => AiFailure.rateLimit(),
      'invalid_response' || 'quality_unavailable' => AiFailure.invalidResponse(),
      'invalid_image' ||
      'unsupported_image_type' ||
      'image_too_large' ||
      'invalid_request' ||
      'validation_error' ||
      'moderation_blocked' =>
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

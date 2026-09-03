export const ErrorCode = {
  noConfiguration: 'no_configuration',
  unauthorized: 'unauthorized',
  /** Verified auth token missing or rejected. */
  authenticationRequired: 'authentication_required',
  /** Firebase App Check attestation missing or rejected. */
  appCheckRequired: 'app_check_required',
  forbidden: 'forbidden',
  rateLimited: 'rate_limited',
  invalidRequest: 'invalid_request',
  invalidImage: 'invalid_image',
  unsupportedImageType: 'unsupported_image_type',
  imageTooLarge: 'image_too_large',
  invalidResponse: 'invalid_response',
  timeout: 'timeout',
  /** Alias used in client contracts for provider abort. */
  providerTimeout: 'provider_timeout',
  network: 'network',
  providerError: 'provider_error',
  moderationBlocked: 'moderation_blocked',
  imageAnalysisUnavailable: 'image_analysis_unavailable',
  /** Writer/repair failed deterministic human-quality / evidence binding. */
  qualityUnavailable: 'quality_unavailable',
  internalError: 'internal_error',
} as const;

export type ErrorCodeName = (typeof ErrorCode)[keyof typeof ErrorCode];

export class ProxyError extends Error {
  constructor(
    readonly code: ErrorCodeName,
    readonly httpStatus: number = 200,
    readonly details?: Record<string, unknown>,
  ) {
    super(code);
    this.name = 'ProxyError';
  }
}

export function fail(
  code: ErrorCodeName,
  httpStatus = 200,
  details?: Record<string, unknown>,
): never {
  throw new ProxyError(code, httpStatus, details);
}

export type ErrorEnvelope = {
  success: false;
  error: { code: ErrorCodeName };
};

export type SuccessEnvelope<T> = {
  success: true;
  data: T;
};

export function errorEnvelope(
  code: ErrorCodeName,
  _details?: Record<string, unknown>,
): ErrorEnvelope {
  return { success: false, error: { code } };
}

export function successEnvelope<T>(data: T): SuccessEnvelope<T> {
  return { success: true, data };
}

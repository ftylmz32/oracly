export const ErrorCode = {
  noConfiguration: 'no_configuration',
  unauthorized: 'unauthorized',
  forbidden: 'forbidden',
  rateLimited: 'rate_limited',
  invalidRequest: 'invalid_request',
  invalidResponse: 'invalid_response',
  timeout: 'timeout',
  network: 'network',
  providerError: 'provider_error',
  imageAnalysisUnavailable: 'image_analysis_unavailable',
  internalError: 'internal_error',
} as const;

export type ErrorCodeName = (typeof ErrorCode)[keyof typeof ErrorCode];

export class ProxyError extends Error {
  constructor(
    readonly code: ErrorCodeName,
    readonly httpStatus: number = 200,
  ) {
    super(code);
    this.name = 'ProxyError';
  }
}

export function fail(code: ErrorCodeName, httpStatus = 200): never {
  throw new ProxyError(code, httpStatus);
}

export type ErrorEnvelope = {
  success: false;
  error: { code: ErrorCodeName };
};

export type SuccessEnvelope<T> = {
  success: true;
  data: T;
};

export function errorEnvelope(code: ErrorCodeName): ErrorEnvelope {
  return { success: false, error: { code } };
}

export function successEnvelope<T>(data: T): SuccessEnvelope<T> {
  return { success: true, data };
}

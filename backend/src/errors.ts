export const ErrorCode = {
  noConfiguration: 'no_configuration',
  unauthorized: 'unauthorized',
  /** Verified auth token missing or rejected. */
  authenticationRequired: 'authentication_required',
  /** Firebase App Check attestation missing or rejected. */
  appCheckRequired: 'app_check_required',
  forbidden: 'forbidden',
  rateLimited: 'rate_limited',
  /** Luna text beyond the one free tarot turn. Not the daily text cap. */
  premiumRequired: 'premium_required',
  /** Free text AI day is full. Not a gem or Premium prompt. */
  dailyQuota: 'daily_quota',
  /** Free coffee, palm, or dream day is full. Not a purchase prompt. */
  coffeeDailyQuota: 'coffee_daily_quota',
  palmDailyQuota: 'palm_daily_quota',
  dreamDailyQuota: 'dream_daily_quota',
  /** Personal daily astrology already written today; the client keeps its copy. */
  astrologyDailyQuota: 'astrology_daily_quota',
  invalidRequest: 'invalid_request',
  invalidImage: 'invalid_image',
  unsupportedImageType: 'unsupported_image_type',
  imageTooLarge: 'image_too_large',
  /** Coffee V2 slotted staging: this exact photo is already used by another slot. */
  duplicateStagedImage: 'duplicate_staged_image',
  invalidResponse: 'invalid_response',
  timeout: 'timeout',
  /** Alias used in client contracts for provider abort. */
  providerTimeout: 'provider_timeout',
  network: 'network',
  providerError: 'provider_error',
  moderationBlocked: 'moderation_blocked',
  /** Dream Phase 3: the dreamer's words need safety guidance, not a reading. */
  dreamSafetyBlocked: 'dream_safety_blocked',
  imageAnalysisUnavailable: 'image_analysis_unavailable',
  /** Writer/repair failed deterministic human-quality / evidence binding. */
  qualityUnavailable: 'quality_unavailable',
  internalError: 'internal_error',
  /** Canonical acceleration cost exceeds authoritative balance. */
  insufficientGems: 'insufficient_gems',
  /** Daily AI spend ceiling. The provider was not called. */
  spendGuard: 'spend_guard',
  /** New Coffee V3 / Palm create has no server-owned reading credit. */
  readingEntitlementRequired: 'reading_entitlement_required',
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

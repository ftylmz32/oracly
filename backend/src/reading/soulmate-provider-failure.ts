/**
 * SM-RL1 — classifies a thrown provider error into exactly the categories
 * needed to decide whether a Soulmate portrait provider failure is safe
 * to retry:
 *
 *   definitive_retryable_rejection    — provider explicitly rejected the
 *                                        request (e.g. rate limit); no
 *                                        output was produced, and the
 *                                        SAME request is expected to
 *                                        eventually succeed.
 *   definitive_nonretryable_rejection — provider explicitly rejected the
 *                                        request for a reason retrying
 *                                        the identical request cannot
 *                                        fix (moderation, invalid
 *                                        request).
 *   ambiguous_transport_outcome       — everything else: timeouts,
 *                                        network resets, generic
 *                                        provider errors, anything where
 *                                        it cannot be proven the
 *                                        provider never produced output.
 *                                        MUST stay on the existing
 *                                        fail-closed provider_outcome_unknown
 *                                        path — never reclassified here.
 *
 * Prefers the transport layer's own typed `ProxyError.code` (already
 * derived from real HTTP status / provider error body in
 * `ai/openai-transport.ts`) over inspecting exception text, per SM-RL1 §8.
 */
import { ErrorCode, ProxyError } from '../errors.js';

export type ProviderFailureKind =
  | 'definitive_retryable_rejection'
  | 'definitive_nonretryable_rejection'
  | 'ambiguous_transport_outcome';

export type ProviderFailureClassification = {
  kind: ProviderFailureKind;
  /** Compact, safe-to-persist error code — never a raw provider body. */
  providerErrorCode: string;
  /** From the provider's own Retry-After, when present and parseable. */
  retryAfterMs?: number;
  /** SM-RL2 — bounded 429 evidence carried through from the transport
   * layer's ProxyError.details, for the worker's `provider_rate_limited`
   * observability log. Never contains secrets/payload (see
   * openai-transport.ts's rateLimitDetails()). */
  requestId?: string;
  rateLimit?: Record<string, string>;
  providerMessage?: string;
};

/** Only these two codes are treated as definitive no-output rejections —
 * every other ProxyError code (timeout, network, generic provider_error,
 * no_configuration, invalid_response, …) stays ambiguous, unchanged. */
const RETRYABLE_REJECTION_CODES: ReadonlySet<string> = new Set([
  ErrorCode.rateLimited,
]);
const NONRETRYABLE_REJECTION_CODES: ReadonlySet<string> = new Set([
  ErrorCode.moderationBlocked,
  ErrorCode.invalidRequest,
]);

export function classifyProviderFailure(error: unknown): ProviderFailureClassification {
  if (error instanceof ProxyError) {
    if (RETRYABLE_REJECTION_CODES.has(error.code)) {
      const retryAfterMs = readRetryAfterMs(error.details);
      const requestId = readRequestId(error.details);
      const rateLimit = readRateLimit(error.details);
      const providerMessage = readProviderMessage(error.details);
      return {
        kind: 'definitive_retryable_rejection',
        providerErrorCode: error.code,
        ...(retryAfterMs != null ? { retryAfterMs } : {}),
        ...(requestId != null ? { requestId } : {}),
        ...(rateLimit != null ? { rateLimit } : {}),
        ...(providerMessage != null ? { providerMessage } : {}),
      };
    }
    if (NONRETRYABLE_REJECTION_CODES.has(error.code)) {
      return { kind: 'definitive_nonretryable_rejection', providerErrorCode: error.code };
    }
    return { kind: 'ambiguous_transport_outcome', providerErrorCode: error.code };
  }
  return {
    kind: 'ambiguous_transport_outcome',
    providerErrorCode: error instanceof Error ? error.name.slice(0, 80) : 'unknown_error',
  };
}

function readRetryAfterMs(details: Record<string, unknown> | undefined): number | undefined {
  const raw = details?.retryAfterMs;
  return typeof raw === 'number' && Number.isFinite(raw) && raw > 0 ? raw : undefined;
}

function readRequestId(details: Record<string, unknown> | undefined): string | undefined {
  const raw = details?.requestId;
  return typeof raw === 'string' && raw.length > 0 ? raw : undefined;
}

function readRateLimit(details: Record<string, unknown> | undefined): Record<string, string> | undefined {
  const raw = details?.rateLimit;
  if (!raw || typeof raw !== 'object') return undefined;
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
    if (typeof value === 'string') out[key] = value;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

function readProviderMessage(details: Record<string, unknown> | undefined): string | undefined {
  const raw = details?.providerMessage;
  return typeof raw === 'string' && raw.length > 0 ? raw : undefined;
}

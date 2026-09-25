/**
 * Phase 6F.1 — Narrative V2 attempt identity for idempotency / duplicate guard.
 * Attempt is NEVER part of the semantic Narrative request fingerprint.
 */
import type { AppConfig } from './config.js';
import { ErrorCode, ProxyError } from './errors.js';

const ATTEMPT_SUFFIX = /:nv2:a([12])$/;

export function parseNarrativeAttemptFromIdempotency(
  key: string | null,
): 1 | 2 | null {
  if (!key) return null;
  const m = ATTEMPT_SUFFIX.exec(key);
  if (!m) return null;
  return Number(m[1]) as 1 | 2;
}

/** Duplicate-guard only — semantic fingerprint stays attempt-free. */
export function narrativeDuplicateFingerprint(
  semanticFingerprint: string,
  attempt: 1 | 2,
): string {
  return `${semanticFingerprint}:attempt-${attempt}`;
}

/**
 * Locked envs: Narrative V2 requires Idempotency-Key ending in `:nv2:a1|a2`.
 * Development may omit (returns null → caller keeps semantic duplicate fp).
 */
export function requireNarrativeAttemptInLockedEnv(
  config: AppConfig,
  idempotencyKey: string | null,
): 1 | 2 | null {
  const attempt = parseNarrativeAttemptFromIdempotency(idempotencyKey);
  const locked =
    config.appEnv === 'production' || config.appEnv === 'staging';
  if (!locked) return attempt;
  if (attempt == null) {
    throw new ProxyError(ErrorCode.invalidRequest);
  }
  return attempt;
}

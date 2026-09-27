/**
 * Dream request identity — the semantic inputs that shape the Dream prompt.
 *
 * Canonical form (v2): request language; sanitized narrative and memory
 * summary, trimmed, lowercased, whitespace runs collapsed; observed symbols
 * and stated emotions normalized the same way, de-duplicated and sorted.
 * Casing/whitespace-only edits are an exact retry. Any other change is a
 * different request: it never shares the duplicate fingerprint or a
 * response-replay slot with the earlier one, even under the same
 * client Idempotency-Key.
 */
import { createHash } from 'node:crypto';
import type { AppLanguage } from './app-language.js';
import { sanitizeText, stringList } from './sanitize.js';

type DreamIdentityInput = {
  payload: Record<string, unknown>;
  language: AppLanguage;
};

const norm = (value: string): string => value.trim().toLowerCase().replace(/\s+/g, ' ');

const normSet = (value: unknown): string[] =>
  [...new Set(stringList(value).map(norm).filter(Boolean))].sort();

export function dreamRequestFingerprint(request: DreamIdentityInput): string {
  const canonical = JSON.stringify({
    language: request.language,
    narrative: norm(sanitizeText(request.payload.narrative)),
    symbols: normSet(request.payload.symbols),
    emotions: normSet(request.payload.emotions),
    memory: norm(sanitizeText(request.payload.memorySummary, 220)),
  });
  return `dream:v2:${createHash('sha256').update(canonical).digest('hex')}`;
}

/**
 * Replay slot for a Dream request: the client key alone is never enough —
 * a completed response is only replayed for the same semantic request.
 */
export function dreamReplayKey(idempotencyKey: string, fingerprint: string): string {
  const digest = createHash('sha256').update(fingerprint).digest('hex').slice(0, 32);
  return `${idempotencyKey}|dream-sem:${digest}`;
}

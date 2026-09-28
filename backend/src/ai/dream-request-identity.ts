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
 *
 * Phase 4A: validated prior-Dream history joins the canonical form only when
 * present (in prompt order), so a no-history request keeps its identity and
 * a material history change never shares a replay slot.
 */
import { createHash } from 'node:crypto';
import type { AppLanguage } from './app-language.js';
import { dreamHistoryIdentity, type DreamHistoryItem } from './dream-history.js';
import { sanitizeText, stringList } from './sanitize.js';

type DreamIdentityInput = {
  payload: Record<string, unknown>;
  language: AppLanguage;
};

const norm = (value: string): string => value.trim().toLowerCase().replace(/\s+/g, ' ');

const normSet = (value: unknown): string[] =>
  [...new Set(stringList(value).map(norm).filter(Boolean))].sort();

export function dreamRequestFingerprint(request: DreamIdentityInput): string {
  const history = dreamHistoryIdentity(request.payload.history as DreamHistoryItem[] | undefined);
  const canonical = JSON.stringify({
    language: request.language,
    narrative: norm(sanitizeText(request.payload.narrative)),
    symbols: normSet(request.payload.symbols),
    emotions: normSet(request.payload.emotions),
    memory: norm(sanitizeText(request.payload.memorySummary, 220)),
    ...(history.length ? { history } : {}),
  });
  return `dream:v2:${createHash('sha256').update(canonical).digest('hex')}`;
}

/**
 * Writer revision of the accepted Dream response contract. A response
 * stored under an earlier writer (accepted by an older, weaker gate) is
 * never replayed under this one. Bump only when acceptance or the writer
 * changes what a success body may contain; the semantic fingerprint
 * (duplicate and billing identity) is deliberately not affected. '4c1': the
 * Phase 4C.1 writer prompt, sanitized symbols and corrected gates.
 * '4c3-astra': the same prompt, written by the frozen Astra writer.
 */
export const DREAM_WRITER_REVISION = '4c3-astra';

/**
 * Replay slot for a Dream request: the client key alone is never enough —
 * a completed response is only replayed for the same semantic request and
 * the same writer revision.
 */
export function dreamReplayKey(idempotencyKey: string, fingerprint: string): string {
  const digest = createHash('sha256').update(fingerprint).digest('hex').slice(0, 32);
  return `${idempotencyKey}|dream-sem:${DREAM_WRITER_REVISION}:${digest}`;
}

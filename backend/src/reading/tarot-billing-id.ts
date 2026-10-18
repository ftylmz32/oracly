/** Paid deep-tarot identity. The settle route uses the same key. */
import { createHash } from 'node:crypto';
import type { ValidatedRequest } from '../ai/validate-request.js';

const OPERATION_ID = /^[A-Za-z0-9._:-]{8,128}$/;
const ATTEMPT_SUFFIX = /:nv2:a([12])$/;

export function tarotCardCount(request: ValidatedRequest): number | null {
  if (request.operation !== 'tarot_reading') return null;
  if (request.mode === 'narrative_v2') return request.narrative.cards.length;
  return request.cards.length;
}

export function isPaidTarot(request: ValidatedRequest): boolean {
  const count = tarotCardCount(request);
  return count != null && count > 1;
}

/** Strips the narrative transport suffix so attempt 2 shares the settle id. */
export function parseTarotBillingId(
  idempotencyKey: string | null,
): { operationId: string; attempt: 1 | 2 | null } | null {
  if (!idempotencyKey) return null;
  const match = ATTEMPT_SUFFIX.exec(idempotencyKey);
  const operationId = match ? idempotencyKey.slice(0, match.index) : idempotencyKey;
  if (!OPERATION_ID.test(operationId)) return null;
  const attempt = match ? (Number(match[1]) as 1 | 2) : null;
  return { operationId, attempt };
}

/** Ledger key shared with POST /v1/gems/tarot/:operationId/settle. */
export function tarotSettleKey(operationId: string): string {
  return `tarot:${createHash('sha256').update(operationId).digest('hex').slice(0, 48)}`;
}

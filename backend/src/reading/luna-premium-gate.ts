/**
 * Luna text is not the 30-operation day cap.
 * One tarot-context oracle stays free per identity. Every other chat or
 * oracle needs a server premium snapshot. The client cannot grant it.
 * TTS is not decided here: the speech body does not name a feature.
 */
import { createHash } from 'node:crypto';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import { freeTextOperationId } from './free-text-quota.js';
import type { SoulmateEntitlementGuard } from './soulmate-entitlement-guard.js';

export const LUNA_FREE = 'lunaFreeText';

export type LunaFreeHold = { operationId: string };

export type LunaAdmission =
  | { action: 'skip' }
  | { action: 'reply'; status: number; payload: unknown }
  | { action: 'allow'; freeHold: LunaFreeHold | null };

export function lunaTextOperation(operation: string): boolean {
  return operation === 'chat' || operation === 'oracle';
}

function locked(config: AppConfig): boolean {
  return config.appEnv === 'production' || config.appEnv === 'staging';
}

function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

function premiumRequired(): LunaAdmission {
  return { action: 'reply', status: 403, payload: errorEnvelope(ErrorCode.premiumRequired) };
}

export async function admitLunaText(input: {
  config: AppConfig;
  store: FirestoreLike | undefined;
  guard: SoulmateEntitlementGuard | undefined;
  operation: string;
  oracleKind: string | null;
  identity: string;
  idempotencyKey: string | null;
}): Promise<LunaAdmission> {
  if (!lunaTextOperation(input.operation)) return { action: 'skip' };
  const enforced = locked(input.config);
  if (!input.guard || !input.store) {
    if (!enforced) return { action: 'skip' };
    return { action: 'reply', status: 503, payload: errorEnvelope(ErrorCode.noConfiguration) };
  }
  if (await input.guard.isPremiumActive(input.identity)) {
    return { action: 'allow', freeHold: null };
  }
  if (input.operation !== 'oracle' || input.oracleKind !== 'tarot') return premiumRequired();
  const operationId = freeTextOperationId(input.idempotencyKey);
  if (!operationId) return { action: 'skip' };
  const ref = input.store.collection(LUNA_FREE).doc(docId(input.identity));
  return input.store.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const row = snap.data();
    const hold: LunaFreeHold = { operationId };
    if (!row) {
      tx.set(ref, { identity: input.identity, operationId, state: 'open' });
      return { action: 'allow' as const, freeHold: hold };
    }
    if (row.identity !== input.identity) return premiumRequired();
    if (row.operationId === operationId) return { action: 'allow' as const, freeHold: hold };
    if (row.state === 'done') return premiumRequired();
    return { action: 'reply' as const, status: 409, payload: errorEnvelope(ErrorCode.rateLimited) };
  });
}

/** Close the one free Luna text. A delivered turn is never returned. */
import { createHash } from 'node:crypto';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { LUNA_FREE, type LunaFreeHold } from './luna-premium-gate.js';

function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

export async function finishLunaFree(
  store: FirestoreLike,
  identity: string,
  hold: LunaFreeHold,
): Promise<void> {
  const ref = store.collection(LUNA_FREE).doc(docId(identity));
  await store.runTransaction(async (tx) => {
    const row = (await tx.get(ref)).data();
    if (!row || row.identity !== identity || row.operationId !== hold.operationId) return;
    tx.set(ref, { identity, operationId: hold.operationId, state: 'done' });
  });
}

export async function failLunaFree(
  store: FirestoreLike,
  identity: string,
  hold: LunaFreeHold,
): Promise<void> {
  const ref = store.collection(LUNA_FREE).doc(docId(identity));
  await store.runTransaction(async (tx) => {
    const row = (await tx.get(ref)).data();
    if (!row || row.identity !== identity || row.operationId !== hold.operationId) return;
    if (row.state === 'done') return;
    tx.delete(ref);
  });
}

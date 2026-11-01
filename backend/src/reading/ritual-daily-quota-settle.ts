/** Close or return a ritual-quota hold. A delivered body is never refunded. */
import { deletionBarrierExists } from '../account/deletion-barrier.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import {
  chargesOf,
  countOf,
  docId,
  RITUAL_ATTEMPTS,
  RITUAL_COUNTERS,
  type RitualHold,
} from './ritual-daily-quota.js';

async function settle(
  store: FirestoreLike,
  identity: string,
  hold: RitualHold,
  done: { body?: string; refund: boolean },
): Promise<void> {
  const counterRef = store.collection(RITUAL_COUNTERS).doc(docId(`${identity}\0${hold.day}\0${hold.kind}`));
  const attemptRef = store.collection(RITUAL_ATTEMPTS).doc(docId(`${identity}\0${hold.kind}\0${hold.fullKey}`));
  await store.runTransaction(async (tx) => {
    // Deleted owner: keep no text and no counter (the sweep removes the rest).
    if (await deletionBarrierExists(tx, store, identity)) return;
    const [counterSnap, attemptSnap] = await Promise.all([tx.get(counterRef), tx.get(attemptRef)]);
    const attempt = attemptSnap.data();
    if (!attempt || attempt.identity !== identity || attempt.status === 'final') return;
    const charges = chargesOf(counterSnap.data());
    const row = charges[hold.operationId];
    let count = countOf(counterSnap.data());
    if (done.body != null) {
      const live = Math.max(0, (row?.live ?? 1) - 1);
      charges[hold.operationId] = { state: 'done', live };
      tx.set(attemptRef, { ...attempt, status: 'final', body: done.body, claimUntilMs: 0 });
    } else if (row && row.state !== 'done' && done.refund) {
      const live = Math.max(0, row.live - 1);
      if (live === 0) {
        delete charges[hold.operationId];
        count = Math.max(0, count - 1);
      } else {
        charges[hold.operationId] = { state: 'open', live };
      }
      tx.set(attemptRef, { ...attempt, status: 'refunded', claimUntilMs: 0 });
    } else if (row) {
      charges[hold.operationId] = { state: row.state, live: Math.max(0, row.live - 1) };
      tx.set(attemptRef, { ...attempt, status: row.state === 'done' ? 'final' : 'open', claimUntilMs: 0 });
    }
    tx.set(counterRef, { identity, day: hold.day, kind: hold.kind, count, charges });
  });
}

export function finishRitualQuota(
  store: FirestoreLike,
  identity: string,
  hold: RitualHold,
  body: unknown,
): Promise<void> {
  const raw = typeof body === 'string' ? body : JSON.stringify(body);
  return settle(store, identity, hold, { body: raw, refund: false });
}

export function failRitualQuota(
  store: FirestoreLike,
  identity: string,
  hold: RitualHold,
): Promise<void> {
  return settle(store, identity, hold, { refund: true });
}

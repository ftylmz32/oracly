/**
 * Account deletion x `readingLegacyDirectAi` (the one-reading pins of legacy
 * Coffee / Palm direct-AI calls, written by `admitOnce`).
 *
 * Deleting account A removes A's pins and keeps B's; a repeated deletion is
 * a no-op; an interrupted deletion never reports `accepted` and the retry
 * finishes the sweep; while A's deletion barrier exists no new pin is written
 * (a request that read A's operation just before the sweep cannot leave an
 * orphan pin behind it).
 *
 * The REAL `FirestoreAccountDeletionRepository` runs unmodified on the
 * in-memory store through a small transport adapter (as in the other
 * deletion tests). No AI, no network.
 */
import { describe, expect, it } from 'vitest';
import type { Firestore } from '@google-cloud/firestore';
import { FirestoreAccountDeletionRepository } from '../src/account/account-deletion.js';
import { ACCOUNT_DELETION_RECEIPTS, accountDeletionReceiptId } from '../src/account/deletion-barrier.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { ReadingOperationRecord } from '../src/reading/operation-model.js';
import { claimedLegacyCoffee, claimedLegacyPalm } from '../src/reading/reading-commerce-gate.js';

const PIN = 'readingLegacyDirectAi';
const A = identityKeyFromSubject('user-a');
const B = identityKeyFromSubject('user-b');

/** Deletion transport over the shared MemoryDocumentStore; `failOnce` makes
 * the next batch commit touching that collection throw (an interrupted run). */
class DeletionAdapter {
  failOnce: string | null = null;
  constructor(private readonly store: MemoryDocumentStore) {}

  collection(name: string) {
    const store = this.store;
    return {
      doc(id: string) {
        const ref = store.collection(name).doc(id);
        return {
          path: `${name}/${id}`,
          get: () => ref.get(),
          async set(data: Record<string, unknown>) {
            await store.runTransaction(async (tx) => { tx.set(ref, data); });
          },
        };
      },
      where(field: string, _op: string, value: unknown) {
        return {
          async get() {
            const docs = [...store.docs.entries()]
              .filter(([path]) => path.startsWith(`${name}/`))
              .filter(([, data]) => data[field] === value)
              .map(([path, data]) => ({
                ref: Object.assign(store.collection(name).doc(path.slice(name.length + 1)), { path }),
                data: () => ({ ...data }),
              }));
            return { docs, empty: docs.length === 0, size: docs.length };
          },
        };
      },
    };
  }

  batch() {
    const refs: { path: string }[] = [];
    const self = this;
    return {
      delete(ref: { path: string }) { refs.push(ref); },
      async commit() {
        const failing = self.failOnce;
        if (failing && refs.some((ref) => ref.path.startsWith(`${failing}/`))) {
          self.failOnce = null;
          throw new Error(`injected failure deleting ${failing}`);
        }
        await self.store.runTransaction(async (tx) => {
          for (const ref of refs) tx.delete(ref as never);
        });
      },
    };
  }

  runTransaction<T>(fn: (tx: never) => Promise<T>): Promise<T> {
    return this.store.runTransaction(fn as never);
  }
}

function world() {
  const store = new MemoryDocumentStore();
  const adapter = new DeletionAdapter(store);
  const deletion = new FirestoreAccountDeletionRepository(adapter as unknown as Firestore, null, null);
  const pins = (owner: string) => [...store.docs.entries()]
    .filter(([path, data]) => path.startsWith(`${PIN}/`) && data.ownerUserId === owner).length;
  const receipt = (owner: string) =>
    store.docs.get(`${ACCOUNT_DELETION_RECEIPTS}/${accountDeletionReceiptId(owner)}`) as Record<string, unknown> | undefined;
  async function seedPins(owner: string, n: number, prefix: string) {
    await store.runTransaction(async (tx) => {
      for (let i = 0; i < n; i++) {
        tx.set(store.collection(PIN).doc(`${prefix}${String(i).padStart(4, '0')}`), {
          ownerUserId: owner, requestKey: `${prefix}-key`, readingType: i % 2 ? 'palm' : 'coffee', admitted: [''],
        });
      }
    });
  }
  return { store, adapter, deletion, pins, receipt, seedPins };
}

function claimed(owner: string, operationId: string, readingType: 'coffee' | 'palm' = 'coffee'): ReadingOperationRecord {
  return {
    operationId, ownerUserId: owner, readingType, status: 'processing',
    createdAtMs: 1_000, readyAtMs: 1_000 + 7_200_000, coffeeCaptureContract: null,
  } as unknown as ReadingOperationRecord;
}

describe('account deletion removes the deleted account\'s legacy direct-AI pins', () => {
  it("A's pins (written by the real gate) are deleted, B's are kept", async () => {
    const w = world();
    const opA = 'a'.repeat(32);
    const opB = 'b'.repeat(32);
    const lookup = { getById: async (id: string) => (id === opA ? claimed(A, opA) : id === opB ? claimed(B, opB) : null) };
    for (const [owner, op] of [[A, opA], [B, opB]] as const) {
      expect(await claimedLegacyCoffee({
        operations: lookup, store: w.store, ownerUserId: owner,
        payload: { operationId: op }, idempotencyKey: `pin-key-${op.slice(0, 4)}`,
      })).toBe(true);
    }
    expect(w.pins(A)).toBe(1);
    expect(w.pins(B)).toBe(1);
    const receipt = await w.deletion.deleteForIdentity(A);
    expect(receipt.status).toBe('accepted');
    expect(w.pins(A)).toBe(0);
    expect(w.pins(B)).toBe(1);
  });

  it('more than one batch (450 pins) is fully removed', async () => {
    const w = world();
    await w.seedPins(A, 450, 'pa');
    await w.seedPins(B, 3, 'pb');
    await w.deletion.deleteForIdentity(A);
    expect(w.pins(A)).toBe(0);
    expect(w.pins(B)).toBe(3);
  });

  it('a repeated deletion is a no-op that returns the same receipt', async () => {
    const w = world();
    await w.seedPins(A, 2, 'pa');
    await w.seedPins(B, 2, 'pb');
    const first = await w.deletion.deleteForIdentity(A);
    const again = await w.deletion.deleteForIdentity(A);
    expect(again).toMatchObject({ receiptId: first.receiptId, status: 'accepted' });
    expect(w.pins(A)).toBe(0);
    expect(w.pins(B)).toBe(2);
  });

  it('an interrupted deletion is never accepted; the retry finishes the pins', async () => {
    const w = world();
    await w.seedPins(A, 3, 'pa');
    await w.seedPins(B, 1, 'pb');
    w.adapter.failOnce = PIN;
    await expect(w.deletion.deleteForIdentity(A)).rejects.toThrow(/injected failure/);
    expect(w.receipt(A)?.status).toBe('deleting');
    expect(w.pins(A)).toBe(3);
    const retried = await w.deletion.deleteForIdentity(A);
    expect(retried.status).toBe('accepted');
    expect(w.pins(A)).toBe(0);
    expect(w.pins(B)).toBe(1);
  });
});

describe('no pin is written for an account being or already deleted', () => {
  for (const readingType of ['coffee', 'palm'] as const) {
    it(`${readingType}: with A's deletion barrier in place, the gate refuses and writes nothing`, async () => {
      const w = world();
      const op = 'c'.repeat(32);
      // A request read A's claimed operation just before the sweep removed it.
      const lookup = { getById: async () => claimed(A, op, readingType) };
      await w.store.runTransaction(async (tx) => {
        tx.set(w.store.collection(ACCOUNT_DELETION_RECEIPTS).doc(accountDeletionReceiptId(A)), {
          receiptId: accountDeletionReceiptId(A), status: 'deleting',
        });
      });
      const gate = readingType === 'coffee' ? claimedLegacyCoffee : claimedLegacyPalm;
      expect(await gate({
        operations: lookup, store: w.store, ownerUserId: A,
        payload: { operationId: op }, idempotencyKey: 'late-pin-key-01',
      })).toBe(false);
      expect(w.pins(A)).toBe(0);
    });
  }

  it('B is not affected by A\'s barrier', async () => {
    const w = world();
    const op = 'd'.repeat(32);
    await w.store.runTransaction(async (tx) => {
      tx.set(w.store.collection(ACCOUNT_DELETION_RECEIPTS).doc(accountDeletionReceiptId(A)), { status: 'deleting' });
    });
    expect(await claimedLegacyCoffee({
      operations: { getById: async () => claimed(B, op) }, store: w.store, ownerUserId: B,
      payload: { operationId: op }, idempotencyKey: 'b-pin-key-0001',
    })).toBe(true);
    expect(w.pins(B)).toBe(1);
  });

  it('after an accepted deletion the account cannot pin again', async () => {
    const w = world();
    await w.deletion.deleteForIdentity(A);
    const op = 'e'.repeat(32);
    expect(await claimedLegacyCoffee({
      operations: { getById: async () => claimed(A, op) }, store: w.store, ownerUserId: A,
      payload: { operationId: op }, idempotencyKey: 'after-delete-01',
    })).toBe(false);
    expect(w.pins(A)).toBe(0);
  });
});

import { describe, expect, it } from 'vitest';
import type { Firestore } from 'firebase-admin/firestore';
import { FirestoreOrderStore } from './store';

type Doc = Record<string, unknown>;
type Ref = { path: string; get(): Promise<{ exists: boolean; data(): Doc | undefined }> };

class FakeFirestore {
  private docs = new Map<string, Doc>(); private queue: Promise<unknown> = Promise.resolve();
  collection(name: string) { return { doc: (id: string): Ref => ({ path: `${name}/${id}`, get: async () => this.snapshot(this.docs, `${name}/${id}`) }) }; }
  runTransaction<T>(work: (tx: { get(ref: Ref): Promise<{ exists: boolean; data(): Doc | undefined }>; create(ref: Ref, data: Doc): void; update(ref: Ref, data: Doc): void }) => Promise<T>): Promise<T> {
    const run = this.queue.then(async () => {
      const working = new Map([...this.docs].map(([key, value]) => [key, structuredClone(value)]));
      const result = await work({
        get: async (ref) => this.snapshot(working, ref.path),
        create: (ref, data) => { if (working.has(ref.path)) throw new Error('already_exists'); working.set(ref.path, structuredClone(data)); },
        update: (ref, data) => { const old = working.get(ref.path); if (!old) throw new Error('not_found'); working.set(ref.path, { ...old, ...structuredClone(data) }); },
      });
      this.docs = working; return result;
    });
    this.queue = run.then(() => undefined, () => undefined); return run;
  }
  private snapshot(source: Map<string, Doc>, path: string) { const value = source.get(path); return { exists: Boolean(value), data: () => value ? structuredClone(value) : undefined }; }
}

const createInput = (idempotencyKey: string, orderId: string) => ({ ownerUserId: 'uid-a', idempotencyKey, orderId, catalogVersion: 'test-v1', priceMinor: 7250, currency: 'TRY' as const, nowMs: 1 });

describe('FirestoreOrderStore transaction contract (fake Firestore)', () => {
  it('creates one durable order for concurrent idempotent requests', async () => {
    const store = new FirestoreOrderStore(new FakeFirestore() as unknown as Firestore);
    const results = await Promise.all([store.createIdempotent(createInput('request_123456789', 'ord_order-a')), store.createIdempotent(createInput('request_123456789', 'ord_order-b'))]);
    expect(results.filter((item) => item.created)).toHaveLength(1);
    expect(results[0].order.orderId).toBe(results[1].order.orderId);
  });

  it('atomically binds one provider payment and consumes one entitlement', async () => {
    const store = new FirestoreOrderStore(new FakeFirestore() as unknown as Firestore);
    await store.createIdempotent(createInput('request_123456789', 'ord_order-a'));
    await store.createIdempotent(createInput('request_987654321', 'ord_order-b'));
    const grants = await Promise.all([
      store.confirmVerifiedPayment({ orderId: 'ord_order-a', providerPaymentId: 'payment-1', priceMinor: 7250, currency: 'TRY', nowMs: 2 }),
      store.confirmVerifiedPayment({ orderId: 'ord_order-b', providerPaymentId: 'payment-1', priceMinor: 7250, currency: 'TRY', nowMs: 2 }),
    ]);
    expect(grants.sort()).toEqual(['granted', 'payment_reused']);
    const consumes = await Promise.all([
      store.consumeEntitlement({ orderId: 'ord_order-a', ownerUserId: 'uid-a', operationId: 'operation-a', nowMs: 3 }),
      store.consumeEntitlement({ orderId: 'ord_order-a', ownerUserId: 'uid-a', operationId: 'operation-b', nowMs: 3 }),
    ]);
    expect(consumes.sort()).toEqual(['consumed', 'not_entitled']);
  });

  it('does not disclose or consume another user order', async () => {
    const store = new FirestoreOrderStore(new FakeFirestore() as unknown as Firestore);
    await store.createIdempotent(createInput('request_123456789', 'ord_order-a'));
    expect(await store.getOwned('ord_order-a', 'uid-b')).toBeNull();
    expect(await store.consumeEntitlement({ orderId: 'ord_order-a', ownerUserId: 'uid-b', operationId: 'operation-a', nowMs: 2 })).toBe('wrong_owner');
  });
});

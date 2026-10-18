import { describe, expect, it } from 'vitest';
import { COFFEE_READING_PRODUCT_ID } from '../../lib/orders/types';
import { createOrderApi } from './api';
import { RequestAuthError, type OrderRequestVerifier } from './auth';
import type { PersistentOrderStore, StoredCoffeeOrder } from './store';

class TestVerifier implements OrderRequestVerifier {
  async verify(request: Request) {
    const auth = request.headers.get('authorization'); const app = request.headers.get('x-firebase-appcheck');
    if (auth !== 'Bearer valid') throw new RequestAuthError('unauthorized');
    if (app !== 'valid') throw new RequestAuthError(app ? 'app_check_invalid' : 'app_check_required');
    return { uid: request.headers.get('x-test-uid') ?? 'uid-a', appId: 'web-app-id' };
  }
}

class TestStore implements PersistentOrderStore {
  readonly orders = new Map<string, StoredCoffeeOrder>(); private readonly requests = new Map<string, string>(); private readonly payments = new Map<string, string>(); private queue: Promise<unknown> = Promise.resolve();
  createIdempotent(input: Parameters<PersistentOrderStore['createIdempotent']>[0]) { return this.atomic(() => { const key = `${input.ownerUserId}:${input.idempotencyKey}`; const old = this.requests.get(key); if (old) return { order: structuredClone(this.orders.get(old)!), created: false }; const order: StoredCoffeeOrder = { orderId: input.orderId, ownerUserId: input.ownerUserId, productId: COFFEE_READING_PRODUCT_ID, catalogVersion: input.catalogVersion, priceMinor: input.priceMinor, currency: input.currency, status: 'created', createdAtMs: input.nowMs, updatedAtMs: input.nowMs, events: [{ status: 'created', atMs: input.nowMs }] }; this.orders.set(order.orderId, order); this.requests.set(key, order.orderId); return { order: structuredClone(order), created: true }; }); }
  async getOwned(orderId: string, uid: string) { const order = this.orders.get(orderId); return order?.ownerUserId === uid ? structuredClone(order) : null; }
  confirmVerifiedPayment(input: Parameters<PersistentOrderStore['confirmVerifiedPayment']>[0]) { return this.atomic(() => { const order = this.orders.get(input.orderId); if (!order || order.priceMinor !== input.priceMinor || order.currency !== input.currency) return 'mismatch' as const; if (order.providerPaymentId === input.providerPaymentId && (order.status === 'entitlement_granted' || order.status === 'entitlement_consumed')) return 'already_applied' as const; const bound = this.payments.get(input.providerPaymentId); if (bound && bound !== input.orderId) return 'payment_reused' as const; this.payments.set(input.providerPaymentId, input.orderId); order.providerPaymentId = input.providerPaymentId; order.status = 'entitlement_granted'; return 'granted' as const; }); }
  consumeEntitlement(input: Parameters<PersistentOrderStore['consumeEntitlement']>[0]) { return this.atomic(() => { const order = this.orders.get(input.orderId); if (!order || order.ownerUserId !== input.ownerUserId) return 'wrong_owner' as const; if (order.status === 'entitlement_consumed') return order.readingOperationId === input.operationId ? 'already_consumed' as const : 'not_entitled' as const; if (order.status !== 'entitlement_granted') return 'not_entitled' as const; order.status = 'entitlement_consumed'; order.readingOperationId = input.operationId; return 'consumed' as const; }); }
  private atomic<T>(fn: () => T): Promise<T> { const run = this.queue.then(fn, fn); this.queue = run.then(() => undefined, () => undefined); return run; }
}

function fixture(store: PersistentOrderStore = new TestStore()) {
  const api = createOrderApi({ verifier: new TestVerifier(), store, config: { catalogVersion: 'test-v1', priceMinor: 7250, currency: 'TRY' }, createOrderId: (() => { let id = 0; return () => `ord_test-order-${++id}`; })(), now: () => 123 });
  const create = (body: unknown, headers: HeadersInit = {}) => api.create(new Request('https://example.test/api/orders', { method: 'POST', headers: { Authorization: 'Bearer valid', 'X-Firebase-AppCheck': 'valid', 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(body) }));
  return { api, store, create };
}

describe('order API', () => {
  it('requires both Firebase UID and App Check', async () => {
    const { api } = fixture();
    expect((await api.create(new Request('https://example.test/api/orders', { method: 'POST' }))).status).toBe(401);
    expect((await api.create(new Request('https://example.test/api/orders', { method: 'POST', headers: { Authorization: 'Bearer valid' } }))).status).toBe(403);
  });
  it('uses only server price and rejects client authority fields', async () => {
    const { create } = fixture();
    expect((await create({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: 'request_123456789', priceMinor: 1 })).status).toBe(400);
    const response = await create({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: 'request_123456789' });
    expect(response.status).toBe(201); expect((await response.json()).order).toMatchObject({ priceMinor: 7250, currency: 'TRY' });
  });
  it('atomically replays concurrent duplicate creates as one order', async () => {
    const { create } = fixture(); const body = { productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: 'request_123456789' };
    const responses = await Promise.all([create(body), create(body)]); const payloads = await Promise.all(responses.map((item) => item.json()));
    expect(responses.map((item) => item.status).sort()).toEqual([200, 201]); expect(payloads[0].order.orderId).toBe(payloads[1].order.orderId);
  });
  it('returns the same 404 for a missing order and another owner', async () => {
    const { api, create } = fixture(); const created = await (await create({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: 'request_123456789' })).json();
    const foreign = new Request('https://example.test', { headers: { Authorization: 'Bearer valid', 'X-Firebase-AppCheck': 'valid', 'X-Test-Uid': 'uid-b' } });
    expect((await api.get(foreign, created.order.orderId)).status).toBe(404); expect((await api.get(foreign, 'ord_not-found')).status).toBe(404);
  });
  it('fails closed when durable storage throws', async () => {
    const store = new TestStore(); store.createIdempotent = async () => { throw new Error('firestore_down'); };
    expect((await fixture(store).create({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: 'request_123456789' })).status).toBe(503);
  });
  it('atomically prevents payment reuse and double entitlement consumption', async () => {
    const { store, create } = fixture(); const typed = store as TestStore;
    const a = await (await create({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: 'request_123456789' })).json();
    const b = await (await create({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: 'request_987654321' })).json();
    expect(await store.confirmVerifiedPayment({ orderId: a.order.orderId, providerPaymentId: 'pay-1', priceMinor: 7250, currency: 'TRY', nowMs: 1 })).toBe('granted');
    expect(await store.confirmVerifiedPayment({ orderId: b.order.orderId, providerPaymentId: 'pay-1', priceMinor: 7250, currency: 'TRY', nowMs: 1 })).toBe('payment_reused');
    const results = await Promise.all([store.consumeEntitlement({ orderId: a.order.orderId, ownerUserId: 'uid-a', operationId: 'op-a', nowMs: 2 }), store.consumeEntitlement({ orderId: a.order.orderId, ownerUserId: 'uid-a', operationId: 'op-b', nowMs: 2 })]);
    expect(results.sort()).toEqual(['consumed', 'not_entitled']); expect(typed.orders.get(a.order.orderId)?.readingOperationId).toBe('op-a');
  });
});

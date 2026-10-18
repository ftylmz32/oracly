import { describe, expect, it } from 'vitest';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import {
  FirestoreWebCoffeeOrderReadingRepository,
} from '../src/reading/web-coffee-order-reading-repository.js';
import { DEFAULT_READING_ADMISSION_LIMITS } from '../src/reading/reading-admission.js';
import type { FirestoreLike, FirestoreTransactionLike } from '../src/billing/entitlement-repository.js';
import { StaticAppCheckVerifier, appCheckHeader, authHeader, signHs256, testApp, testConfig } from './helpers.js';

const SECRET = 'web-order-test-secret';
const WEB_APP = '1:123:web:oracly';
const IOS_APP = '1:123:ios:oracly';
const ANDROID_APP = '1:123:android:oracly';
const ORDER_ID = 'order_12345678';
const BODY = {
  readingType: 'coffee',
  sourceRequestId: 'web_coffee_request_1234',
  language: 'tr',
  intention: 'Yakın geleceğimde beni neler bekliyor?',
  coffeeInputContract: 'trusted_intention_v1',
  coffeeCaptureContract: 'three_view_v3',
};

function config() {
  return testConfig({
    AI_JWT_SECRET: SECRET,
    ORACLY_COFFEE_V3_ENABLED: 'true',
    ORACLY_WEB_COFFEE_ORDER_READING_ENABLED: 'true',
    FIREBASE_WEB_APP_CHECK_APP_IDS: WEB_APP,
  });
}

function headers(subject = 'user-1') {
  return { ...authHeader(signHs256(SECRET, { sub: subject })), ...appCheckHeader('good-token') };
}

function seedOrder(store: MemoryDocumentStore, status = 'entitlement_granted', ownerUserId = 'user-1') {
  store.docs.set(`webCoffeeOrders/${ORDER_ID}`, {
    orderId: ORDER_ID,
    ownerUserId,
    productId: 'coffee_reading_single_v1',
    catalogVersion: 'test',
    priceMinor: 1,
    currency: 'TRY',
    status,
    createdAtMs: 1,
    updatedAtMs: 1,
    events: [{ status, atMs: 1 }],
  });
}

async function build(store: MemoryDocumentStore, appId = WEB_APP, repository?: FirestoreWebCoffeeOrderReadingRepository) {
  return testApp(config(), undefined, {
    appCheck: new StaticAppCheckVerifier('good-token', appId),
    readingOperationRepository: new FirestoreReadingOperationRepository(store),
    webCoffeeOrderReadingRepository: repository ?? new FirestoreWebCoffeeOrderReadingRepository(store, DEFAULT_READING_ADMISSION_LIMITS),
  });
}

describe('paid web Coffee V3 bridge', () => {
  it.each(['created', 'payment_pending', 'payment_verified', 'failed', 'refunded'])('rejects an order in %s state', async (status) => {
    const store = new MemoryDocumentStore(); seedOrder(store, status);
    const app = await build(store);
    const response = await app.inject({ method: 'POST', url: `/v1/web/coffee-orders/${ORDER_ID}/reading-operation`, headers: headers(), payload: BODY });
    expect(response.statusCode).toBe(409);
    expect(store.read(`webCoffeeOrders/${ORDER_ID}`).data()?.status).toBe(status);
    await app.close();
  });

  it('allows only one operation under two concurrent requests', async () => {
    const store = new MemoryDocumentStore(); seedOrder(store);
    const app = await build(store);
    const request = () => app.inject({ method: 'POST', url: `/v1/web/coffee-orders/${ORDER_ID}/reading-operation`, headers: headers(), payload: BODY });
    const [first, second] = await Promise.all([request(), request()]);
    expect(first.statusCode).toBe(200); expect(second.statusCode).toBe(200);
    const ids = [first.json().data.operationId, second.json().data.operationId];
    expect(new Set(ids).size).toBe(1);
    expect([...store.docs.keys()].filter((key) => key.startsWith('readingOperations/'))).toHaveLength(1);
    await app.close();
  });

  it('hides another user order and leaves it untouched', async () => {
    const store = new MemoryDocumentStore(); seedOrder(store);
    const app = await build(store);
    const response = await app.inject({ method: 'POST', url: `/v1/web/coffee-orders/${ORDER_ID}/reading-operation`, headers: headers('attacker'), payload: BODY });
    expect(response.statusCode).toBe(404);
    expect(store.read(`webCoffeeOrders/${ORDER_ID}`).data()?.status).toBe('entitlement_granted');
    await app.close();
  });

  it('returns the existing operation for an idempotent retry', async () => {
    const store = new MemoryDocumentStore(); seedOrder(store);
    const app = await build(store);
    const request = () => app.inject({ method: 'POST', url: `/v1/web/coffee-orders/${ORDER_ID}/reading-operation`, headers: headers(), payload: BODY });
    const first = await request(); const second = await request();
    expect(second.json().data.operationId).toBe(first.json().data.operationId);
    await app.close();
  });

  it('blocks a verified web app from bypassing payment through the legacy create API', async () => {
    const store = new MemoryDocumentStore();
    const app = await build(store);
    const response = await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(), payload: BODY });
    expect(response.statusCode).toBe(403);
    expect([...store.docs.keys()].filter((key) => key.startsWith('readingOperations/'))).toHaveLength(0);
    await app.close();
  });

  it.each([IOS_APP, ANDROID_APP])('preserves legacy create and status for mobile app %s', async (appId) => {
    const store = new MemoryDocumentStore();
    const app = await build(store, appId);
    const created = await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(), payload: BODY });
    expect(created.statusCode).toBe(200);
    const status = await app.inject({ method: 'GET', url: `/v1/reading-operations/${created.json().data.operationId}`, headers: headers() });
    expect(status.statusCode).toBe(200);
    expect(status.json().data.readingType).toBe('coffee');
    await app.close();
  });

  it('rolls back entitlement and operation writes when the transaction fails', async () => {
    const base = new MemoryDocumentStore(); seedOrder(base);
    const failing: FirestoreLike = {
      collection: (name) => base.collection(name),
      runTransaction: <T>(fn: (tx: FirestoreTransactionLike) => Promise<T>) =>
        base.runTransaction(async (tx) => { await fn(tx); throw new Error('commit_failed'); }),
    };
    const repository = new FirestoreWebCoffeeOrderReadingRepository(failing, DEFAULT_READING_ADMISSION_LIMITS);
    const app = await build(base, WEB_APP, repository);
    const response = await app.inject({ method: 'POST', url: `/v1/web/coffee-orders/${ORDER_ID}/reading-operation`, headers: headers(), payload: BODY });
    expect(response.statusCode).toBe(503);
    expect(base.read(`webCoffeeOrders/${ORDER_ID}`).data()?.status).toBe('entitlement_granted');
    expect([...base.docs.keys()].filter((key) => key.startsWith('readingOperations/'))).toHaveLength(0);
    await app.close();
  });

  it('fails closed for bypassed App Check and an unrecognized verified App ID', async () => {
    const store = new MemoryDocumentStore(); seedOrder(store);
    const unknown = await build(store, 'unknown-app');
    const response = await unknown.inject({ method: 'POST', url: `/v1/web/coffee-orders/${ORDER_ID}/reading-operation`, headers: headers(), payload: BODY });
    expect(response.statusCode).toBe(503);
    await unknown.close();
  });
});

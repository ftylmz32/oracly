import { createHash, randomBytes } from 'node:crypto';
import { Firestore } from '@google-cloud/firestore';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { FirestoreOrderStore } from '../../website/src/server/orders/store.js';
import { COFFEE_READING_PRODUCT_ID } from '../../website/src/lib/orders/types.js';
import { loadConfig } from '../src/config.js';
import { SCHEMA_VERSION, type ReadingOperationRecord } from '../src/reading/operation-model.js';
import { idempotencyKeyFor } from '../src/reading/operation-repository.js';
import { DEFAULT_READING_ADMISSION_LIMITS, readingAdmissionRefs } from '../src/reading/reading-admission.js';
import {
  FirestoreWebCoffeeOrderReadingRepository,
  WebOrderReadingError,
} from '../src/reading/web-coffee-order-reading-repository.js';

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
const PROJECT = process.env.GCLOUD_PROJECT ?? 'demo-oracly-web-2f';
const DATABASE = process.env.FIRESTORE_DATABASE_ID ?? '(default)';
const suite = describe.runIf(Boolean(emulator));

suite('real Firestore Emulator web order transaction', () => {
  const adminApp = initializeApp({ projectId: PROJECT }, `orders-${Date.now()}`);
  const websiteDb = getFirestore(adminApp, DATABASE);
  const backendDb = new Firestore({ projectId: PROJECT, databaseId: DATABASE });
  const websiteStore = new FirestoreOrderStore(websiteDb);
  const repository = new FirestoreWebCoffeeOrderReadingRepository(backendDb, DEFAULT_READING_ADMISSION_LIMITS);

  beforeAll(() => {
    const config = loadConfig({ FIREBASE_PROJECT_ID: PROJECT, FIRESTORE_DATABASE_ID: DATABASE });
    expect(config.firebaseProjectId).toBe(PROJECT);
    expect(config.firestoreDatabaseId).toBe(DATABASE);
    expect(websiteDb.projectId).toBe(PROJECT);
    expect(websiteDb.databaseId).toBe(DATABASE);
  });

  afterAll(async () => {
    await backendDb.terminate();
    await deleteApp(adminApp);
  });

  async function entitled(owner = 'uid-owner') {
    const suffix = randomBytes(8).toString('hex');
    const orderId = `emu_order_${suffix}`;
    await websiteStore.createIdempotent({
      ownerUserId: owner,
      idempotencyKey: `emu_request_${suffix}`,
      orderId,
      catalogVersion: 'emulator-v1',
      priceMinor: 1,
      currency: 'TRY',
      nowMs: Date.now(),
    });
    expect(await websiteStore.confirmVerifiedPayment({
      orderId,
      providerPaymentId: `emu_payment_${suffix}`,
      priceMinor: 1,
      currency: 'TRY',
      nowMs: Date.now(),
    })).toBe('granted');
    return { orderId, suffix, owner };
  }

  function record(suffix: string, ownerUserId = 'sub:emulator-owner', sourceRequestId = `emu_source_${suffix}`): ReadingOperationRecord {
    const now = Date.now();
    return {
      schemaVersion: SCHEMA_VERSION,
      operationId: randomBytes(16).toString('hex'),
      ownerUserId,
      readingType: 'coffee',
      language: 'tr',
      status: 'waiting',
      createdAtMs: now,
      readyAtMs: now + 60_000,
      updatedAtMs: now,
      sourceRequestId,
      resultId: null,
      failureCode: null,
      acceleratedAtMs: null,
      gemDebitId: null,
      executionStartedAtMs: null,
      executionMode: null,
      coffeeIntention: 'Genel niyet',
      coffeeInputContract: 'trusted_intention_v1',
      coffeeCaptureContract: 'three_view_v3',
    };
  }

  it('shares the canonical product and the same emulator project/database across website and backend SDKs', async () => {
    expect(COFFEE_READING_PRODUCT_ID).toBe('oracly_coffee_single_v1');
    const created = await entitled();
    const raw = await backendDb.collection('webCoffeeOrders').doc(created.orderId).get();
    expect(raw.data()?.productId).toBe(COFFEE_READING_PRODUCT_ID);
  });

  it('atomically permits only one operation for two concurrent starts and keeps records consistent', async () => {
    const order = await entitled();
    const first = record(order.suffix);
    const second = record(`${order.suffix}_competing`, first.ownerUserId);
    const attempts = await Promise.allSettled([
      repository.createFromEntitlement({ orderId: order.orderId, firebaseUid: order.owner, record: first }),
      repository.createFromEntitlement({ orderId: order.orderId, firebaseUid: order.owner, record: second }),
    ]);
    const successes = attempts.filter((attempt) => attempt.status === 'fulfilled');
    const failures = attempts.filter((attempt) => attempt.status === 'rejected');
    expect(successes).toHaveLength(1);
    expect(failures).toHaveLength(1);
    expect(failures[0]).toMatchObject({ reason: { code: 'conflict' } });
    const accepted = successes[0];
    if (accepted?.status !== 'fulfilled') throw new Error('expected one accepted transaction');
    const storedOrder = await websiteStore.getOwned(order.orderId, order.owner);
    expect(storedOrder?.status).toBe('entitlement_consumed');
    expect(storedOrder?.readingOperationId).toBe(accepted.value.record.operationId);
    const storedOperations = await backendDb.collection('readingOperations')
      .where('ownerUserId', '==', first.ownerUserId).get();
    expect(storedOperations.docs.map((doc) => doc.id)).toEqual([accepted.value.record.operationId]);
  });

  it('returns the same operation when the consumed order is retried', async () => {
    const order = await entitled();
    const initial = record(order.suffix);
    const first = await repository.createFromEntitlement({ orderId: order.orderId, firebaseUid: order.owner, record: initial });
    const retry = await repository.createFromEntitlement({ orderId: order.orderId, firebaseUid: order.owner, record: { ...record(order.suffix), sourceRequestId: initial.sourceRequestId } });
    expect(retry.created).toBe(false);
    expect(retry.record.operationId).toBe(first.record.operationId);
  });

  it('rejects another owner without consuming the order', async () => {
    const order = await entitled();
    await expect(repository.createFromEntitlement({ orderId: order.orderId, firebaseUid: 'uid-attacker', record: record(order.suffix) }))
      .rejects.toMatchObject({ code: 'wrong_owner' });
    expect((await websiteStore.getOwned(order.orderId, order.owner))?.status).toBe('entitlement_granted');
  });

  it('rolls back the right, operation, idempotency and admission writes after an injected transaction failure', async () => {
    const order = await entitled();
    const candidate = record(order.suffix, `sub:rollback-${order.suffix}`);
    const failing = new FirestoreWebCoffeeOrderReadingRepository(
      backendDb,
      DEFAULT_READING_ADMISSION_LIMITS,
      () => { throw new Error('injected_before_commit'); },
    );
    await expect(failing.createFromEntitlement({ orderId: order.orderId, firebaseUid: order.owner, record: candidate }))
      .rejects.toBeInstanceOf(WebOrderReadingError);
    expect((await websiteStore.getOwned(order.orderId, order.owner))?.status).toBe('entitlement_granted');
    expect((await backendDb.collection('readingOperations').doc(candidate.operationId).get()).exists).toBe(false);
    const keyId = createHash('sha256').update(idempotencyKeyFor(candidate)).digest('hex');
    expect((await backendDb.collection('readingOperationKeys').doc(keyId).get()).exists).toBe(false);
    const refs = readingAdmissionRefs(
      backendDb,
      candidate.ownerUserId,
      DEFAULT_READING_ADMISSION_LIMITS.createRateWindowMs,
      candidate.createdAtMs,
    );
    expect((await refs.admission.get()).exists).toBe(false);
    expect((await refs.rate.get()).exists).toBe(false);
  });
});

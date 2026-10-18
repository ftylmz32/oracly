import { createHash } from 'node:crypto';
import { Firestore, Timestamp } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { parseStoredRecord, toStoredDocument, type ReadingOperationRecord } from './operation-model.js';
import {
  admitNewReadingInTx,
  readingAdmissionLimitsFromConfig,
  readingAdmissionRefs,
  ReadingAdmissionDenied,
  type ReadingAdmissionLimits,
} from './reading-admission.js';
import { idempotencyKeyFor, type CreateStored } from './operation-repository.js';
import { WEB_COFFEE_READING_PRODUCT_ID } from './web-coffee-product.js';

const ORDERS = 'webCoffeeOrders';
const OPERATIONS = 'readingOperations';
const KEYS = 'readingOperationKeys';

export type WebOrderReadingErrorCode =
  | 'wrong_owner'
  | 'not_entitled'
  | 'conflict'
  | 'rate_limited'
  | 'unavailable';

export class WebOrderReadingError extends Error {
  constructor(readonly code: WebOrderReadingErrorCode) {
    super(code);
    this.name = 'WebOrderReadingError';
  }
}

export interface WebCoffeeOrderReadingRepository {
  createFromEntitlement(input: {
    orderId: string;
    firebaseUid: string;
    record: ReadingOperationRecord;
  }): Promise<CreateStored>;
}

export class FirestoreWebCoffeeOrderReadingRepository implements WebCoffeeOrderReadingRepository {
  constructor(
    private readonly firestore: FirestoreLike,
    private readonly limits: ReadingAdmissionLimits,
    /** Test-only failure injection; production construction never supplies it. */
    private readonly beforeCommit?: () => void,
  ) {}

  async createFromEntitlement(input: {
    orderId: string;
    firebaseUid: string;
    record: ReadingOperationRecord;
  }): Promise<CreateStored> {
    const orderRef = this.firestore.collection(ORDERS).doc(input.orderId);
    const opRef = this.firestore.collection(OPERATIONS).doc(input.record.operationId);
    const key = idempotencyKeyFor(input.record);
    const keyRef = this.firestore.collection(KEYS).doc(digest(key));
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const orderSnap = await tx.get(orderRef);
        const order = parseOrder(orderSnap.data());
        if (!order || order.ownerUserId !== input.firebaseUid) {
          throw new WebOrderReadingError('wrong_owner');
        }

        if (order.status === 'entitlement_consumed') {
          if (!order.readingOperationId) throw new WebOrderReadingError('unavailable');
          const existing = parseStoredRecord(
            (await tx.get(this.firestore.collection(OPERATIONS).doc(order.readingOperationId))).data(),
          );
          if (!existing || existing.ownerUserId !== input.record.ownerUserId ||
              existing.readingType !== 'coffee' ||
              existing.coffeeCaptureContract !== 'three_view_v3') {
            throw new WebOrderReadingError('unavailable');
          }
          if (existing.sourceRequestId !== input.record.sourceRequestId ||
              existing.coffeeIntention !== input.record.coffeeIntention ||
              existing.coffeeInputContract !== 'trusted_intention_v1') {
            throw new WebOrderReadingError('conflict');
          }
          return { created: false, record: existing };
        }
        if (order.status !== 'entitlement_granted') {
          throw new WebOrderReadingError('not_entitled');
        }

        const keySnap = await tx.get(keyRef);
        if (keySnap.exists) throw new WebOrderReadingError('conflict');
        const refs = readingAdmissionRefs(
          this.firestore,
          input.record.ownerUserId,
          this.limits.createRateWindowMs,
          input.record.createdAtMs,
        );
        const admissionSnap = await tx.get(refs.admission);
        const rateSnap = await tx.get(refs.rate);
        admitNewReadingInTx(tx, {
          ownerUserId: input.record.ownerUserId,
          nowMs: input.record.createdAtMs,
          limits: this.limits,
          admissionSnap,
          rateSnap,
          refs,
        });
        tx.set(opRef, toStoredDocument(input.record));
        tx.set(keyRef, {
          operationId: input.record.operationId,
          ownerUserId: input.record.ownerUserId,
          readingType: 'coffee',
          expiresAt: Timestamp.fromMillis(input.record.createdAtMs + 30 * 86_400_000),
        });
        tx.update(orderRef, {
          status: 'entitlement_consumed',
          readingOperationId: input.record.operationId,
          updatedAtMs: input.record.createdAtMs,
          events: [...order.events, { status: 'entitlement_consumed', atMs: input.record.createdAtMs }],
        });
        this.beforeCommit?.();
        return { created: true, record: input.record };
      });
    } catch (error) {
      if (error instanceof WebOrderReadingError) throw error;
      if (error instanceof ReadingAdmissionDenied) throw new WebOrderReadingError('rate_limited');
      throw new WebOrderReadingError('unavailable');
    }
  }
}

export class FailClosedWebCoffeeOrderReadingRepository implements WebCoffeeOrderReadingRepository {
  async createFromEntitlement(): Promise<CreateStored> {
    throw new WebOrderReadingError('unavailable');
  }
}

export function createWebCoffeeOrderReadingRepository(config: AppConfig): WebCoffeeOrderReadingRepository {
  if (!config.webCoffeeOrderReadingEnabled || !config.firebaseProjectId ||
      !config.entitlementDurableRequired || config.firebaseWebAppCheckAppIds.length === 0) {
    return new FailClosedWebCoffeeOrderReadingRepository();
  }
  try {
    const firestore = new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    });
    return new FirestoreWebCoffeeOrderReadingRepository(
      firestore,
      readingAdmissionLimitsFromConfig(config),
    );
  } catch {
    return new FailClosedWebCoffeeOrderReadingRepository();
  }
}

type StoredOrder = {
  ownerUserId: string;
  status: string;
  readingOperationId?: string;
  events: Array<Record<string, unknown>>;
};

function parseOrder(data: Record<string, unknown> | undefined): StoredOrder | null {
  if (!data || data.productId !== WEB_COFFEE_READING_PRODUCT_ID || typeof data.ownerUserId !== 'string' ||
      typeof data.status !== 'string' || !Array.isArray(data.events)) return null;
  return data as StoredOrder;
}

function digest(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

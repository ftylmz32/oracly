/**
 * Durable reading-operation store.
 * Production uses the existing Firestore client. Absence of Firestore fails
 * closed — never an in-process map pretending to be durable.
 */
import { createHash } from 'node:crypto';
import { Firestore, Timestamp } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import {
  parseStoredRecord,
  toStoredDocument,
  type ReadingOperationRecord,
} from './operation-model.js';

const OPERATIONS = 'readingOperations';
const KEYS = 'readingOperationKeys';

export class ReadingStorageUnavailable extends Error {
  constructor() {
    super('reading_storage_unavailable');
    this.name = 'ReadingStorageUnavailable';
  }
}

export type CreateStored = {
  created: boolean;
  record: ReadingOperationRecord;
};

export interface ReadingOperationRepository {
  createIfAbsent(
    record: ReadingOperationRecord,
    idempotencyKey: string,
  ): Promise<CreateStored>;
  getById(operationId: string): Promise<ReadingOperationRecord | null>;
  /**
   * Owner-checked mutation inside one storage transaction.
   * Throws ReadingStorageUnavailable when missing or owned by someone else.
   */
  mutate(
    operationId: string,
    ownerUserId: string,
    apply: (current: ReadingOperationRecord) => ReadingOperationRecord,
  ): Promise<ReadingOperationRecord>;
}

export class FirestoreReadingOperationRepository
  implements ReadingOperationRepository
{
  constructor(private readonly firestore: FirestoreLike) {}

  async createIfAbsent(
    record: ReadingOperationRecord,
    idempotencyKey: string,
  ): Promise<CreateStored> {
    const keyRef = this.firestore.collection(KEYS).doc(documentIdFor(idempotencyKey));
    const opRef = this.firestore.collection(OPERATIONS).doc(record.operationId);
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const keySnap = await tx.get(keyRef);
        if (keySnap.exists) {
          const existingId = keySnap.data()?.operationId;
          if (typeof existingId !== 'string') {
            throw new ReadingStorageUnavailable();
          }
          const existing = await tx.get(
            this.firestore.collection(OPERATIONS).doc(existingId),
          );
          const parsed = parseStoredRecord(existing.data());
          if (!parsed) throw new ReadingStorageUnavailable();
          return { created: false, record: parsed };
        }
        tx.set(opRef, toStoredDocument(record));
        tx.set(keyRef, {
          operationId: record.operationId,
          ownerUserId: record.ownerUserId,
          readingType: record.readingType,
          expiresAt: Timestamp.fromMillis(record.createdAtMs + 30 * 86_400_000),
        });
        return { created: true, record };
      });
    } catch (error) {
      if (error instanceof ReadingStorageUnavailable) throw error;
      throw new ReadingStorageUnavailable();
    }
  }

  async getById(operationId: string): Promise<ReadingOperationRecord | null> {
    try {
      const snap = await this.firestore
        .collection(OPERATIONS)
        .doc(operationId)
        .get();
      if (!snap.exists) return null;
      return parseStoredRecord(snap.data());
    } catch {
      throw new ReadingStorageUnavailable();
    }
  }

  async mutate(
    operationId: string,
    ownerUserId: string,
    apply: (current: ReadingOperationRecord) => ReadingOperationRecord,
  ): Promise<ReadingOperationRecord> {
    const ref = this.firestore.collection(OPERATIONS).doc(operationId);
    try {
      return await this.firestore.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const current = parseStoredRecord(snap.data());
        if (!current || current.ownerUserId !== ownerUserId) {
          throw new ReadingStorageUnavailable();
        }
        const next = apply(current);
        if (next.operationId !== current.operationId) {
          throw new ReadingStorageUnavailable();
        }
        if (next.ownerUserId !== ownerUserId) {
          throw new ReadingStorageUnavailable();
        }
        tx.set(ref, toStoredDocument(next));
        return next;
      });
    } catch (error) {
      if (error instanceof ReadingStorageUnavailable) throw error;
      throw error;
    }
  }
}

export class FailClosedReadingOperationRepository
  implements ReadingOperationRepository
{
  async createIfAbsent(): Promise<CreateStored> {
    throw new ReadingStorageUnavailable();
  }

  async getById(): Promise<ReadingOperationRecord | null> {
    throw new ReadingStorageUnavailable();
  }

  async mutate(): Promise<ReadingOperationRecord> {
    throw new ReadingStorageUnavailable();
  }
}

let sharedFirestore: Firestore | null = null;

export function createReadingOperationRepository(
  config: AppConfig,
): ReadingOperationRepository {
  if (!config.firebaseProjectId || !config.entitlementDurableRequired) {
    return new FailClosedReadingOperationRepository();
  }
  try {
    sharedFirestore ??= new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    });
    return new FirestoreReadingOperationRepository(sharedFirestore);
  } catch {
    return new FailClosedReadingOperationRepository();
  }
}

export function idempotencyKeyFor(input: {
  ownerUserId: string;
  readingType: string;
  sourceRequestId: string;
}): string {
  return `${input.ownerUserId}\0${input.readingType}\0${input.sourceRequestId}`;
}

function documentIdFor(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

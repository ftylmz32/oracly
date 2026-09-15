/**
 * Durable store for a ReadingOperation's structured input (BATCH 5G).
 * Same fail-closed contract as operation-repository.ts: absence of
 * Firestore never falls back to an in-process map pretending to be
 * durable — callers must treat ReadingInputStorageUnavailable as a real
 * failure.
 */
import { Firestore } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import {
  parseStoredInputRecord,
  toStoredInputDocument,
  type ReadingOperationInputRecord,
} from './operation-input-model.js';

const INPUTS = 'readingOperationInputs';

export class ReadingInputStorageUnavailable extends Error {
  constructor() {
    super('reading_input_storage_unavailable');
    this.name = 'ReadingInputStorageUnavailable';
  }
}

export interface ReadingOperationInputRepository {
  upsert(record: ReadingOperationInputRecord): Promise<void>;
  get(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingOperationInputRecord | null>;
}

export class FirestoreReadingOperationInputRepository
  implements ReadingOperationInputRepository
{
  constructor(private readonly firestore: FirestoreLike) {}

  async upsert(record: ReadingOperationInputRecord): Promise<void> {
    const ref = this.firestore.collection(INPUTS).doc(record.operationId);
    try {
      await this.firestore.runTransaction(async (tx) => {
        tx.set(ref, toStoredInputDocument(record));
      });
    } catch {
      throw new ReadingInputStorageUnavailable();
    }
  }

  async get(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingOperationInputRecord | null> {
    try {
      const snap = await this.firestore.collection(INPUTS).doc(operationId).get();
      if (!snap.exists) return null;
      const parsed = parseStoredInputRecord(snap.data());
      if (!parsed || parsed.ownerUserId !== ownerUserId) return null;
      return parsed;
    } catch {
      throw new ReadingInputStorageUnavailable();
    }
  }
}

export class FailClosedReadingOperationInputRepository
  implements ReadingOperationInputRepository
{
  async upsert(): Promise<void> {
    throw new ReadingInputStorageUnavailable();
  }

  async get(): Promise<ReadingOperationInputRecord | null> {
    throw new ReadingInputStorageUnavailable();
  }
}

let sharedFirestore: Firestore | null = null;

export function createReadingOperationInputRepository(
  config: AppConfig,
): ReadingOperationInputRepository {
  if (!config.firebaseProjectId || !config.entitlementDurableRequired) {
    return new FailClosedReadingOperationInputRepository();
  }
  try {
    sharedFirestore ??= new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    });
    return new FirestoreReadingOperationInputRepository(sharedFirestore);
  } catch {
    return new FailClosedReadingOperationInputRepository();
  }
}

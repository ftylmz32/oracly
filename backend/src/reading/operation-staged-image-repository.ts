/**
 * Durable store for a Coffee/Palm staged-image metadata record (BATCH 5I).
 * Same fail-closed contract as operation-repository.ts / operation-input-
 * repository.ts: absence of Firestore never falls back to an in-process
 * map pretending to be durable.
 */
import { Firestore } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import {
  COFFEE_V2_SLOTS,
  COFFEE_V3_STAGED_SLOTS,
  parseStoredStagedImageRecord,
  stagedDocId,
  toStoredStagedImageDocument,
  type CoffeeStagedSlot,
  type CoffeeV2Slot,
  type CoffeeV3RetiredStagedSlot,
  type CoffeeV3StagedSlot,
  type ReadingStagedImageRecord,
} from './operation-staged-image-model.js';

const STAGED_IMAGES = 'readingOperationStagedImages';

export class ReadingStagedImageStorageUnavailable extends Error {
  constructor() {
    super('reading_staged_image_storage_unavailable');
    this.name = 'ReadingStagedImageStorageUnavailable';
  }
}

export interface ReadingStagedImageRepository {
  upsert(record: ReadingStagedImageRecord): Promise<void>;
  get(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord | null>;
  delete(operationId: string): Promise<void>;
  /**
   * Additive Coffee V2 slot API (Phase 2A) — never used by the legacy
   * unslotted path. `upsert`/`delete` above already handle slotted records
   * correctly (doc id derives from `record.slot` / the slot param), these
   * are read-side convenience only.
   */
  getSlot(
    operationId: string,
    slot: CoffeeV2Slot,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord | null>;
  listSlots(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord[]>;
  deleteSlot(operationId: string, slot: CoffeeV2Slot): Promise<void>;
  /**
   * Coffee V3 three-view staged slots (plus the retired four-view slots,
   * read/delete only, for cleanup). Separate from the V2 methods above so
   * `listSlots` keeps returning only V2 records.
   */
  getCoffeeV3Slot(
    operationId: string,
    slot: CoffeeV3StagedSlot | CoffeeV3RetiredStagedSlot,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord | null>;
  listCoffeeV3Slots(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord[]>;
  deleteCoffeeV3Slot(operationId: string, slot: CoffeeV3StagedSlot | CoffeeV3RetiredStagedSlot): Promise<void>;
}

export class FirestoreReadingStagedImageRepository
  implements ReadingStagedImageRepository
{
  constructor(private readonly firestore: FirestoreLike) {}

  async upsert(record: ReadingStagedImageRecord): Promise<void> {
    const ref = this.firestore
      .collection(STAGED_IMAGES)
      .doc(stagedDocId(record.operationId, record.slot));
    try {
      await this.firestore.runTransaction(async (tx) => {
        tx.set(ref, toStoredStagedImageDocument(record));
      });
    } catch {
      throw new ReadingStagedImageStorageUnavailable();
    }
  }

  async get(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord | null> {
    try {
      const snap = await this.firestore.collection(STAGED_IMAGES).doc(operationId).get();
      if (!snap.exists) return null;
      const parsed = parseStoredStagedImageRecord(snap.data());
      if (!parsed || parsed.ownerUserId !== ownerUserId) return null;
      return parsed;
    } catch {
      throw new ReadingStagedImageStorageUnavailable();
    }
  }

  async delete(operationId: string): Promise<void> {
    const ref = this.firestore.collection(STAGED_IMAGES).doc(operationId);
    try {
      await this.firestore.runTransaction(async (tx) => {
        tx.delete(ref);
      });
    } catch {
      throw new ReadingStagedImageStorageUnavailable();
    }
  }

  async getSlot(
    operationId: string,
    slot: CoffeeV2Slot,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord | null> {
    return this.readSlot(operationId, slot, ownerUserId);
  }

  async getCoffeeV3Slot(
    operationId: string,
    slot: CoffeeV3StagedSlot | CoffeeV3RetiredStagedSlot,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord | null> {
    return this.readSlot(operationId, slot, ownerUserId);
  }

  /** Exactly the three live V3 staged slots, by direct doc lookups (no query / index). Never V2 records. */
  async listCoffeeV3Slots(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord[]> {
    const records = await Promise.all(
      COFFEE_V3_STAGED_SLOTS.map((slot) => this.readSlot(operationId, slot, ownerUserId)),
    );
    return records.filter((r): r is ReadingStagedImageRecord => r !== null);
  }

  async deleteCoffeeV3Slot(operationId: string, slot: CoffeeV3StagedSlot | CoffeeV3RetiredStagedSlot): Promise<void> {
    return this.deleteSlotDoc(operationId, slot);
  }

  private async readSlot(
    operationId: string,
    slot: CoffeeStagedSlot,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord | null> {
    try {
      const snap = await this.firestore
        .collection(STAGED_IMAGES)
        .doc(stagedDocId(operationId, slot))
        .get();
      if (!snap.exists) return null;
      const parsed = parseStoredStagedImageRecord(snap.data());
      if (!parsed || parsed.ownerUserId !== ownerUserId || parsed.slot !== slot) {
        return null;
      }
      return parsed;
    } catch {
      throw new ReadingStagedImageStorageUnavailable();
    }
  }

  async listSlots(
    operationId: string,
    ownerUserId: string,
  ): Promise<ReadingStagedImageRecord[]> {
    // Slots are a small, fixed, known set -- direct per-doc lookups avoid
    // needing a Firestore query/index, matching this codebase's existing
    // preference for deterministic key lookups over queries.
    const records = await Promise.all(
      COFFEE_V2_SLOTS.map((slot) => this.getSlot(operationId, slot, ownerUserId)),
    );
    return records.filter((r): r is ReadingStagedImageRecord => r !== null);
  }

  async deleteSlot(operationId: string, slot: CoffeeV2Slot): Promise<void> {
    return this.deleteSlotDoc(operationId, slot);
  }

  private async deleteSlotDoc(operationId: string, slot: CoffeeStagedSlot): Promise<void> {
    const ref = this.firestore.collection(STAGED_IMAGES).doc(stagedDocId(operationId, slot));
    try {
      await this.firestore.runTransaction(async (tx) => {
        tx.delete(ref);
      });
    } catch {
      throw new ReadingStagedImageStorageUnavailable();
    }
  }
}

export class FailClosedReadingStagedImageRepository
  implements ReadingStagedImageRepository
{
  async upsert(): Promise<void> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async get(): Promise<ReadingStagedImageRecord | null> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async delete(): Promise<void> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async getSlot(): Promise<ReadingStagedImageRecord | null> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async getCoffeeV3Slot(): Promise<ReadingStagedImageRecord | null> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async listCoffeeV3Slots(): Promise<ReadingStagedImageRecord[]> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async deleteCoffeeV3Slot(): Promise<void> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async listSlots(): Promise<ReadingStagedImageRecord[]> {
    throw new ReadingStagedImageStorageUnavailable();
  }

  async deleteSlot(): Promise<void> {
    throw new ReadingStagedImageStorageUnavailable();
  }
}

let sharedFirestore: Firestore | null = null;

export function createReadingStagedImageRepository(
  config: AppConfig,
): ReadingStagedImageRepository {
  if (!config.firebaseProjectId || !config.entitlementDurableRequired) {
    return new FailClosedReadingStagedImageRepository();
  }
  try {
    sharedFirestore ??= new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    });
    return new FirestoreReadingStagedImageRepository(sharedFirestore);
  } catch {
    return new FailClosedReadingStagedImageRepository();
  }
}

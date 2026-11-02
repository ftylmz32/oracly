import { createHash } from 'node:crypto';
import { Firestore, FieldValue, Timestamp } from '@google-cloud/firestore';
import { Storage } from '@google-cloud/storage';
import type { AppConfig } from '../config.js';
import { ACCOUNT_DELETION_RECEIPTS, accountDeletionReceiptId } from './deletion-barrier.js';
import { isOwnedSpeechObject, speechOwnerPrefix } from '../reading/speech-retention.js';

export type DeletionReceipt = {
  receiptId: string;
  status: 'accepted';
  completedAt: string;
  deletedDocuments: number;
  deletedObjects: number;
  anonymizedPurchaseBindings: number;
};

export interface AccountDeletionRepository {
  deleteForIdentity(identityKey: string): Promise<DeletionReceipt>;
}

/** What one owner-data sweep removed. */
export type DeletionSweep = {
  deletedDocuments: number;
  deletedObjects: number;
  anonymizedPurchaseBindings: number;
};

export type ReconcileResult =
  | ({ status: 'reconciled' } & DeletionSweep)
  | { status: 'skipped'; reason: 'no_receipt' | 'not_accepted' };

export const DELETE_COLLECTIONS = [
  'userProfiles', 'orMemory', 'lunaMemory', 'personalization',
  'readingOperations', 'readingOperationKeys', 'readingOperationResults', 'readingOperationActive',
  'gemBalances', 'gemTransactions', 'gemTransactionKeys',
  'readingOperationStagedImages', 'readingOperationInputs', 'readingNotificationTokens',
  'readingNotificationTokenOwners',
  'readingProviderStages',
  'aiContentReports',
  // SMD1 — Soulmate portrait metadata; the GCS object itself is deleted
  // below (mirrors the staged-image GCS cleanup right above it).
  'readingSoulmatePortraits',
  // Legacy Coffee / Palm direct-AI one-reading pins (request key + phases;
  // no reading content). Written only behind the deletion barrier check.
  'readingLegacyDirectAi',
] as const;

/** Free-quota records owned by an `identity` field: the attempts keep the
 * delivered response `body`; the day counters keep the charge rows. Their
 * writers check the deletion barrier, so nothing reappears after the sweep. */
export const IDENTITY_COLLECTIONS = [
  'ritualDailyQuota', 'ritualDailyQuotaAttempts',
  'freeTextQuota', 'freeTextQuotaAttempts',
] as const;

/** Aşama 4C — OR/Luna reply audio records, owned by an `identity` field:
 * `speechGrants` keep the reply text; `speechPreviewDay` the daily preview
 * cap. Their writers check the deletion barrier (`luna-speech-gate.ts`,
 * `luna-speech-settle.ts`). The clips live under `speech-clips/<owner>/`. */
export const SPEECH_COLLECTIONS = ['speechGrants', 'speechPreviewDay'] as const;

/** Production deletion is retry-safe: every delete is idempotent and the receipt
 * becomes `accepted` only after content cleanup and purchase-binding
 * anonymization finish. WAVE 3.2 — the SAME receipt document is first written
 * as a `deleting` barrier (no TTL) before any destructive operation, so a
 * worker still in flight for this identity can never re-create owner-scoped
 * state during or after the sweep (see `deletion-barrier.ts`). */
export class FirestoreAccountDeletionRepository implements AccountDeletionRepository {
  constructor(
    private readonly firestore: Firestore,
    private readonly storage: Storage | null,
    private readonly bucket: string | null,
  ) {}

  async deleteForIdentity(identityKey: string): Promise<DeletionReceipt> {
    const receiptId = accountDeletionReceiptId(identityKey);
    const receiptRef = this.firestore.collection(ACCOUNT_DELETION_RECEIPTS).doc(receiptId);
    const existing = await receiptRef.get();
    if (existing.exists && existing.data()?.status === 'accepted') {
      // Aşama 4K — an `accepted` receipt does not prove the data is gone: an
      // older revision may have accepted without sweeping every collection,
      // and a late writer may have added a record afterwards. Re-run the same
      // idempotent, owner-scoped sweep (the barrier is already in place) and
      // answer with the original receipt. A failure propagates.
      await this.reconcileAccepted(receiptRef, identityKey);
      return existing.data() as DeletionReceipt;
    }
    // Barrier first: committed before the first destructive operation and
    // never removed by the sweep. A retry after a partial run finds the
    // `deleting` barrier already in place and simply resumes the sweep.
    if (!existing.exists) {
      await receiptRef.set({
        receiptId,
        status: 'deleting',
        deletionStartedAt: new Date().toISOString(),
      });
    }

    const { deletedDocuments, deletedObjects, anonymizedPurchaseBindings } =
      await this.sweepOwnedData(identityKey);

    const receipt: DeletionReceipt = {
      receiptId,
      status: 'accepted',
      completedAt: new Date().toISOString(),
      deletedDocuments,
      deletedObjects,
      anonymizedPurchaseBindings,
    };
    await receiptRef.set({
      ...receipt,
      expiresAt: Timestamp.fromMillis(Date.parse(receipt.completedAt) + 30 * 86_400_000),
    });
    return receipt;
  }

  /** Aşama 4K — for the one-off reconciliation tool: re-sweeps the data of
   * an identity whose deletion was already ACCEPTED (exact match: the receipt
   * id is derived from the identity key). Never creates a receipt, never
   * touches an identity without an accepted one. */
  async reconcileDeletedIdentity(identityKey: string): Promise<ReconcileResult> {
    const receiptRef = this.firestore.collection(ACCOUNT_DELETION_RECEIPTS)
      .doc(accountDeletionReceiptId(identityKey));
    const existing = await receiptRef.get();
    if (!existing.exists) return { status: 'skipped', reason: 'no_receipt' };
    if (existing.data()?.status !== 'accepted') return { status: 'skipped', reason: 'not_accepted' };
    return { status: 'reconciled', ...(await this.reconcileAccepted(receiptRef, identityKey)) };
  }

  /** Re-sweep under an accepted receipt; records what it removed on the
   * receipt (its TTL `expiresAt` is left unchanged). */
  private async reconcileAccepted(
    receiptRef: ReturnType<ReturnType<Firestore['collection']>['doc']>,
    identityKey: string,
  ): Promise<DeletionSweep> {
    const swept = await this.sweepOwnedData(identityKey);
    const removed = swept.deletedDocuments + swept.deletedObjects + swept.anonymizedPurchaseBindings;
    if (removed > 0) {
      const current = (await receiptRef.get()).data() ?? {};
      const prior = (key: string) => (typeof current[key] === 'number' ? (current[key] as number) : 0);
      await receiptRef.update({
        reconciledAt: new Date().toISOString(),
        reconciledDocuments: prior('reconciledDocuments') + swept.deletedDocuments,
        reconciledObjects: prior('reconciledObjects') + swept.deletedObjects,
        reconciledPurchaseBindings: prior('reconciledPurchaseBindings') + swept.anonymizedPurchaseBindings,
      });
    }
    return swept;
  }

  /** The owner-scoped, idempotent sweep (unchanged from the deletion path):
   * objects first, then documents, then purchase-binding anonymization. Any
   * failure propagates, so nothing is ever reported as cleaned when it is not. */
  private async sweepOwnedData(identityKey: string): Promise<DeletionSweep> {
    let deletedDocuments = 0;
    let deletedObjects = 0;
    const staged = await this.firestore.collection('readingOperationStagedImages')
      .where('ownerUserId', '==', identityKey).get();
    // SMD1 — durably-generated Soulmate portraits, same GCS bucket, own
    // path prefix (soulmate-portraits/) and metadata collection.
    const portraits = await this.firestore.collection('readingSoulmatePortraits')
      .where('ownerUserId', '==', identityKey).get();
    if (this.storage && this.bucket) {
      for (const doc of staged.docs) {
        const path = doc.data().objectPath;
        if (typeof path === 'string' && path.startsWith('reading-staging/')) {
          await this.storage.bucket(this.bucket).file(path).delete({ ignoreNotFound: true });
          deletedObjects++;
        }
      }
      for (const doc of portraits.docs) {
        const path = doc.data().objectPath;
        if (typeof path === 'string' && path.startsWith('soulmate-portraits/')) {
          await this.storage.bucket(this.bucket).file(path).delete({ ignoreNotFound: true });
          deletedObjects++;
        }
      }
    } else if (!staged.empty || !portraits.empty) {
      throw new Error('account_deletion_object_store_unavailable');
    }

    // Aşama 4C — every clip and probe under this owner's own prefix, including
    // orphans no record points at. Listed only AFTER the barrier committed:
    // a render finishing later sees the barrier in its finish transaction and
    // deletes its own clip. Objects go first and documents after, so a failed
    // object delete leaves the records (and the `deleting` receipt) in place
    // and the retry lists the prefix again.
    deletedObjects += await this.deleteSpeechObjects(identityKey);

    const sweeps = [
      ...DELETE_COLLECTIONS.map((collection) => ({ collection, field: 'ownerUserId' })),
      ...IDENTITY_COLLECTIONS.map((collection) => ({ collection, field: 'identity' })),
      ...SPEECH_COLLECTIONS.map((collection) => ({ collection, field: 'identity' })),
    ];
    for (const { collection, field } of sweeps) {
      const snapshot = await this.firestore.collection(collection)
        .where(field, '==', identityKey).get();
      for (let offset = 0; offset < snapshot.docs.length; offset += 400) {
        const batch = this.firestore.batch();
        for (const doc of snapshot.docs.slice(offset, offset + 400)) batch.delete(doc.ref);
        await batch.commit();
      }
      deletedDocuments += snapshot.docs.length;
    }

    const bindings = await this.firestore.collection('purchaseBindings')
      .where('identityKey', '==', identityKey).get();
    for (const binding of bindings.docs) {
      await this.firestore.runTransaction(async tx => {
        const current = await tx.get(binding.ref);
        if (!current.exists || current.data()?.identityKey !== identityKey) return;
        tx.update(binding.ref, {
          identityKey: null,
          rebindEligible: true,
          previousOwnerHash: digest(identityKey),
          ownerHistoryHashes: FieldValue.arrayUnion(digest(identityKey)),
          ownershipRemovedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
    }
    return { deletedDocuments, deletedObjects, anonymizedPurchaseBindings: bindings.size };
  }

  /** Deletes `speech-clips/<owner>/` objects of exactly this identity.
   * Idempotent (missing objects are fine); any other failure propagates so
   * the receipt is never accepted. Without object storage it fails closed
   * when speech records exist, as for staged images above. */
  private async deleteSpeechObjects(identityKey: string): Promise<number> {
    if (!this.storage || !this.bucket) {
      for (const collection of SPEECH_COLLECTIONS) {
        const owned = await this.firestore.collection(collection)
          .where('identity', '==', identityKey).get();
        if (!owned.empty) throw new Error('account_deletion_object_store_unavailable');
      }
      return 0;
    }
    const prefix = speechOwnerPrefix(identityKey);
    const bucket = this.storage.bucket(this.bucket);
    const [files] = await bucket.getFiles({ prefix });
    let deleted = 0;
    for (const file of files) {
      // Defense in depth: never trust the listing beyond the exact shape.
      if (!file.name.startsWith(prefix) || !isOwnedSpeechObject(file.name, identityKey)) continue;
      await bucket.file(file.name).delete({ ignoreNotFound: true });
      deleted++;
    }
    return deleted;
  }
}

export class FailClosedAccountDeletionRepository implements AccountDeletionRepository {
  async deleteForIdentity(): Promise<DeletionReceipt> {
    throw new Error('account_deletion_storage_unavailable');
  }
}

export function createAccountDeletionRepository(config: AppConfig): AccountDeletionRepository {
  if (!config.firebaseProjectId) return new FailClosedAccountDeletionRepository();
  try {
    return new FirestoreAccountDeletionRepository(
      new Firestore({ projectId: config.firebaseProjectId, databaseId: config.firestoreDatabaseId }),
      config.readingStagingBucket ? new Storage({ projectId: config.firebaseProjectId }) : null,
      config.readingStagingBucket,
    );
  } catch {
    return new FailClosedAccountDeletionRepository();
  }
}

function digest(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

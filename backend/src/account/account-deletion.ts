import { createHash } from 'node:crypto';
import { Firestore, FieldValue, Timestamp } from '@google-cloud/firestore';
import { Storage } from '@google-cloud/storage';
import type { AppConfig } from '../config.js';

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

const DELETE_COLLECTIONS = [
  'userProfiles', 'orMemory', 'lunaMemory', 'personalization',
  'readingOperations', 'readingOperationKeys', 'readingOperationResults', 'readingOperationActive',
  'gemBalances', 'gemTransactions', 'gemTransactionKeys',
  'readingOperationStagedImages', 'readingOperationInputs', 'readingNotificationTokens',
  'readingNotificationTokenOwners',
  'readingProviderStages',
  // SMD1 — Soulmate portrait metadata; the GCS object itself is deleted
  // below (mirrors the staged-image GCS cleanup right above it).
  'readingSoulmatePortraits',
] as const;

/** Production deletion is retry-safe: every delete is idempotent and the receipt
 * is written only after content cleanup and purchase-binding anonymization finish. */
export class FirestoreAccountDeletionRepository implements AccountDeletionRepository {
  constructor(
    private readonly firestore: Firestore,
    private readonly storage: Storage | null,
    private readonly bucket: string | null,
  ) {}

  async deleteForIdentity(identityKey: string): Promise<DeletionReceipt> {
    const receiptId = digest(`account-delete\0${identityKey}`);
    const receiptRef = this.firestore.collection('accountDeletionReceipts').doc(receiptId);
    const existing = await receiptRef.get();
    if (existing.exists && existing.data()?.status === 'accepted') {
      return existing.data() as DeletionReceipt;
    }

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

    for (const collection of DELETE_COLLECTIONS) {
      const snapshot = await this.firestore.collection(collection)
        .where('ownerUserId', '==', identityKey).get();
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

    const receipt: DeletionReceipt = {
      receiptId,
      status: 'accepted',
      completedAt: new Date().toISOString(),
      deletedDocuments,
      deletedObjects,
      anonymizedPurchaseBindings: bindings.size,
    };
    await receiptRef.set({
      ...receipt,
      expiresAt: Timestamp.fromMillis(Date.parse(receipt.completedAt) + 30 * 86_400_000),
    });
    return receipt;
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

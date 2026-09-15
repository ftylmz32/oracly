/**
 * SMD1 — durable, private, authenticated storage for a generated Soulmate
 * portrait. The portrait must survive the worker's own process/retry
 * lifecycle and be fetchable ONLY by its owner, never via a public URL.
 *
 * Reuses the EXISTING `ReadingStagedObjectStore` GCS wrapper (same bucket
 * as staged input images, `config.readingStagingBucket` — no new bucket,
 * no Cloud/infra change) under a distinct path prefix, plus a Firestore
 * metadata document for the ownership check + retention window. The
 * metadata document is the SAME shape account-deletion cleanup already
 * expects from a `.where('ownerUserId', '==', identityKey)` collection
 * scan (see `account/account-deletion.ts`).
 */
import { Timestamp } from '@google-cloud/firestore';
import { createHash } from 'node:crypto';
import type { SoulmateIdentity } from '../ai/soulmate-prompt.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { ReadingStagedObjectStore } from './staged-object-store.js';

const METADATA_COLLECTION = 'readingSoulmatePortraits';
export const SOULMATE_PORTRAIT_RETENTION_MS = 30 * 86_400_000;

export type SoulmatePortraitMetadata = {
  operationId: string;
  ownerUserId: string;
  contentType: string;
  byteSize: number;
  sha256: string;
  identity: SoulmateIdentity;
  createdAtMs: number;
};

export type SoulmatePortrait = {
  bytes: Buffer;
  contentType: string;
  byteSize: number;
  sha256: string;
  identity: SoulmateIdentity;
};

export interface SoulmatePortraitStore {
  put(input: {
    operationId: string;
    ownerUserId: string;
    bytes: Buffer;
    contentType: string;
    identity: SoulmateIdentity;
  }): Promise<void>;
  /** Returns null for a not-found OR an owner mismatch — same external
   * shape either way, so a caller can never distinguish "doesn't exist"
   * from "exists but isn't yours". */
  get(operationId: string, ownerUserId: string): Promise<SoulmatePortrait | null>;
  delete(operationId: string): Promise<void>;
}

export function soulmatePortraitObjectPath(
  operationId: string,
  ownerUserId: string,
  ext: string,
): string {
  const ownerPathKey = ownerUserId.replace(/[^A-Za-z0-9_-]/g, '_');
  return `soulmate-portraits/${ownerPathKey}/${operationId}.${ext}`;
}

function extFor(contentType: string): string {
  if (contentType === 'image/png') return 'png';
  if (contentType === 'image/webp') return 'webp';
  return 'jpg';
}

export class GcsSoulmatePortraitStore implements SoulmatePortraitStore {
  constructor(
    private readonly objects: ReadingStagedObjectStore,
    private readonly firestore: FirestoreLike,
  ) {}

  private metaRef(operationId: string) {
    return this.firestore.collection(METADATA_COLLECTION).doc(operationId);
  }

  async put(input: {
    operationId: string;
    ownerUserId: string;
    bytes: Buffer;
    contentType: string;
    identity: SoulmateIdentity;
  }): Promise<void> {
    const path = soulmatePortraitObjectPath(
      input.operationId,
      input.ownerUserId,
      extFor(input.contentType),
    );
    await this.objects.put(path, input.bytes, input.contentType);
    const sha256 = createHash('sha256').update(input.bytes).digest('hex');
    const nowMs = Date.now();
    await this.firestore.runTransaction(async (tx) => {
      tx.set(this.metaRef(input.operationId), {
        operationId: input.operationId,
        ownerUserId: input.ownerUserId,
        objectPath: path,
        contentType: input.contentType,
        byteSize: input.bytes.length,
        sha256,
        identity: input.identity,
        createdAtMs: nowMs,
        expiresAt: Timestamp.fromMillis(nowMs + SOULMATE_PORTRAIT_RETENTION_MS),
      });
    });
  }

  async get(operationId: string, ownerUserId: string): Promise<SoulmatePortrait | null> {
    const snap = await this.metaRef(operationId).get();
    const data = snap.data();
    if (!data || data.ownerUserId !== ownerUserId) return null;
    const path = data.objectPath;
    const contentType = data.contentType;
    const byteSize = data.byteSize;
    const sha256 = data.sha256;
    const identity = data.identity;
    if (typeof path !== 'string' || typeof contentType !== 'string' ||
        typeof byteSize !== 'number' || typeof sha256 !== 'string' ||
        !identity || typeof identity !== 'object') return null;
    const bytes = await this.objects.get(path);
    if (!bytes) return null;
    const actualSha256 = createHash('sha256').update(bytes).digest('hex');
    if (bytes.length !== byteSize || actualSha256 !== sha256) return null;
    return { bytes, contentType, byteSize, sha256, identity: identity as SoulmateIdentity };
  }

  async delete(operationId: string): Promise<void> {
    const snap = await this.metaRef(operationId).get();
    const path = snap.data()?.objectPath;
    if (typeof path === 'string') {
      await this.objects.delete(path);
    }
    await this.firestore.runTransaction(async (tx) => {
      tx.delete(this.metaRef(operationId));
    });
  }
}

/** Storage is unreachable/unconfigured — never a fake success. */
export class FailClosedSoulmatePortraitStore implements SoulmatePortraitStore {
  async put(): Promise<void> {
    throw new Error('soulmate_portrait_storage_unavailable');
  }
  async get(): Promise<SoulmatePortrait | null> {
    return null;
  }
  async delete(): Promise<void> {}
}

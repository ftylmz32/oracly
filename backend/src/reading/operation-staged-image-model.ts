/**
 * BATCH 5I — durable metadata for a Coffee/Palm staged input image. The
 * image bytes themselves live only in GCS (staged-object-store.ts); this
 * is the small Firestore reference document, mirroring the same pattern
 * already used for Soulmate's structured input (operation-input-model.ts).
 */
import { Timestamp } from '@google-cloud/firestore';
export const STAGED_IMAGE_SCHEMA_VERSION = 1;

export type StagedImageReadingType = 'coffee' | 'palm';

export function isStagedImageReadingType(value: unknown): value is StagedImageReadingType {
  return value === 'coffee' || value === 'palm';
}

/**
 * Coffee V2 slotted staging (Phase 2A) — additive, optional. Absence of a
 * slot on a request/record means the legacy single-image behavior, byte-
 * for-byte unchanged. A slot is valid only for readingType 'coffee'; Palm
 * always uses the legacy unslotted path. Canonical order matters for
 * future processing (cup_primary, cup_secondary, saucer) — never reorder.
 */
export const COFFEE_V2_SLOTS = ['cup_primary', 'cup_secondary', 'saucer'] as const;

export type CoffeeV2Slot = (typeof COFFEE_V2_SLOTS)[number];

export function isCoffeeV2Slot(value: unknown): value is CoffeeV2Slot {
  return (COFFEE_V2_SLOTS as readonly unknown[]).includes(value);
}

const EXTENSION_FOR_MIME: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/jpg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

/** Extension is derived ONLY from a validated MIME type — never client input. */
export function extensionForMime(mimeType: string): string | null {
  return EXTENSION_FOR_MIME[mimeType] ?? null;
}

const CHECKSUM = /^[a-f0-9]{64}$/;

export type StagedImageUploadState = 'pending' | 'complete';

export type ReadingStagedImageRecord = {
  schemaVersion: typeof STAGED_IMAGE_SCHEMA_VERSION;
  operationId: string;
  ownerUserId: string;
  readingType: StagedImageReadingType;
  objectPath: string;
  contentType: string;
  byteSize: number;
  checksumSha256: string;
  uploadState: StagedImageUploadState;
  handSide?: 'left' | 'right';
  /** Coffee V2 only (Phase 2A). Absent = legacy single-image record. */
  slot?: CoffeeV2Slot;
  createdAtMs: number;
  updatedAtMs: number;
};

/**
 * Owner path segment is the SAME hashed identityKey used everywhere else
 * (never a raw Firebase UID, never an email) — made path-safe. Extension
 * comes only from `extensionForMime`. Authorization never relies on this
 * path being unguessable; the bucket is fully private and every access is
 * re-checked against the owning ReadingOperation.
 *
 * `slot` absent -> legacy path, byte-for-byte unchanged
 * (`.../{operationId}/input.{ext}`). `slot` present -> Coffee V2 path
 * (`.../{operationId}/{slot}.{ext}`), independent per slot so the three
 * canonical slots can never collide with each other or with a legacy object.
 */
export function stagedObjectPath(input: {
  readingType: StagedImageReadingType;
  ownerUserId: string;
  operationId: string;
  ext: string;
  slot?: CoffeeV2Slot;
}): string {
  const ownerPathKey = input.ownerUserId.replace(/[^A-Za-z0-9_-]/g, '_');
  const fileName = input.slot ? input.slot : 'input';
  return `reading-staging/${input.readingType}/${ownerPathKey}/${input.operationId}/${fileName}.${input.ext}`;
}

/**
 * Firestore document id for a staged-image record. `slot` absent -> the
 * legacy id (`operationId` alone), unchanged. `slot` present -> an
 * independent deterministic id per slot, so the three canonical Coffee V2
 * slots are three separate documents that can never overwrite one another
 * or the legacy document.
 */
export function stagedDocId(operationId: string, slot?: CoffeeV2Slot): string {
  return slot ? `${operationId}--${slot}` : operationId;
}

export function toStoredStagedImageDocument(
  record: ReadingStagedImageRecord,
): Record<string, unknown> {
  return {
    schemaVersion: record.schemaVersion,
    operationId: record.operationId,
    ownerUserId: record.ownerUserId,
    readingType: record.readingType,
    objectPath: record.objectPath,
    contentType: record.contentType,
    byteSize: record.byteSize,
    checksumSha256: record.checksumSha256,
    uploadState: record.uploadState,
    ...(record.handSide ? { handSide: record.handSide } : {}),
    ...(record.slot ? { slot: record.slot } : {}),
    createdAtMs: record.createdAtMs,
    updatedAtMs: record.updatedAtMs,
    expiresAt: Timestamp.fromMillis(record.updatedAtMs + 24 * 60 * 60 * 1000),
  };
}

export function parseStoredStagedImageRecord(
  data: Record<string, unknown> | undefined,
): ReadingStagedImageRecord | null {
  if (!data) return null;
  if (data.schemaVersion !== STAGED_IMAGE_SCHEMA_VERSION) return null;
  if (typeof data.operationId !== 'string' || data.operationId.length < 8) return null;
  if (typeof data.ownerUserId !== 'string' || data.ownerUserId.length < 4) return null;
  if (!isStagedImageReadingType(data.readingType)) return null;
  if (typeof data.objectPath !== 'string' || !data.objectPath) return null;
  if (typeof data.contentType !== 'string' || !data.contentType) return null;
  if (typeof data.byteSize !== 'number' || data.byteSize <= 0) return null;
  if (typeof data.checksumSha256 !== 'string' || !CHECKSUM.test(data.checksumSha256)) {
    return null;
  }
  if (data.uploadState !== 'pending' && data.uploadState !== 'complete') return null;
  if (data.handSide != null && data.handSide !== 'left' && data.handSide !== 'right') return null;
  if (data.slot != null && !isCoffeeV2Slot(data.slot)) return null;
  if (typeof data.createdAtMs !== 'number' || typeof data.updatedAtMs !== 'number') {
    return null;
  }
  return {
    schemaVersion: STAGED_IMAGE_SCHEMA_VERSION,
    operationId: data.operationId,
    ownerUserId: data.ownerUserId,
    readingType: data.readingType,
    objectPath: data.objectPath,
    contentType: data.contentType,
    byteSize: data.byteSize,
    checksumSha256: data.checksumSha256,
    uploadState: data.uploadState,
    handSide: data.handSide as 'left' | 'right' | undefined,
    slot: data.slot as CoffeeV2Slot | undefined,
    createdAtMs: data.createdAtMs,
    updatedAtMs: data.updatedAtMs,
  };
}

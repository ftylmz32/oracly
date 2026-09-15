/**
 * BATCH 5I — the durable staging boundary for Coffee/Palm input images.
 * Every action re-derives ownership from the authenticated identity via
 * the existing ReadingOperationService — never trusts a client-supplied
 * path, owner, or bucket reference.
 */
import { createHash } from 'node:crypto';
import { isAllowedImageMime, validateImageBytes } from '../ai/image.js';
import { sanitizeText } from '../ai/sanitize.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, fail } from '../errors.js';
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import {
  COFFEE_V2_SLOTS,
  extensionForMime,
  isCoffeeV2Slot,
  isStagedImageReadingType,
  STAGED_IMAGE_SCHEMA_VERSION,
  stagedObjectPath,
  type CoffeeV2Slot,
  type ReadingStagedImageRecord,
  type StagedImageReadingType,
} from './operation-staged-image-model.js';
import type { ReadingStagedImageRepository } from './operation-staged-image-repository.js';
import { ReadingOperationError, type ReadingOperationService } from './operation-service.js';
import type { ReadingStagedObjectStore } from './staged-object-store.js';

export type StagedImageInput = {
  ownerUserId: string;
  operationId: string;
  mimeType: unknown;
  imageBase64: unknown;
  handSide?: unknown;
  /** Coffee V2 only (Phase 2A). Absent -> legacy single-image behavior. */
  slot?: unknown;
};

export type StagedImageStatus = {
  operationId: string;
  staged: true;
  contentType: string;
  byteSize: number;
  readyAtMs: number;
};

export class ReadingStagedImageService {
  constructor(
    private readonly repository: ReadingStagedImageRepository,
    private readonly objects: ReadingStagedObjectStore,
    private readonly operations: ReadingOperationService,
    private readonly clock: ServerClock,
    private readonly config: AppConfig,
    private readonly onCleanupFailure?: (event: {
      event: 'staged_cleanup_failed';
      operationId: string;
      readingType?: string;
      stage: 'object' | 'metadata';
    }) => void,
  ) {}

  /**
   * Two-phase: metadata `pending` -> object write -> metadata `complete`.
   * A crash between any two steps leaves `uploadState != 'complete'`,
   * which `retrieveForProcessing` below refuses to use — the operation can
   * never be claimed/processed off a partial stage. Retrying the SAME
   * operationId overwrites the same object path (idempotent) — no
   * duplicate object, no duplicate paid AI call.
   */
  async stage(input: StagedImageInput): Promise<StagedImageStatus> {
    const operation = await this.operations.get(input.ownerUserId, input.operationId);
    if (!isStagedImageReadingType(operation.readingType)) {
      throw new ReadingOperationError('not_found');
    }
    const readingType: StagedImageReadingType = operation.readingType;
    const handSide =
      readingType === 'palm' && (input.handSide === 'left' || input.handSide === 'right')
        ? input.handSide
        : undefined;
    if (readingType === 'palm' && !handSide) {
      throw new ReadingOperationError('invalid');
    }
    // Coffee V2 slotted staging (Phase 2A) — additive and optional. A slot
    // is only ever valid for Coffee; Palm must fail closed rather than
    // silently ignore an unexpected slot. An unknown slot value also fails
    // closed rather than being coerced into a canonical one.
    let slot: CoffeeV2Slot | undefined;
    if (input.slot != null) {
      if (readingType !== 'coffee' || !isCoffeeV2Slot(input.slot)) {
        throw new ReadingOperationError('invalid');
      }
      slot = input.slot;
    }

    const mime = sanitizeText(input.mimeType, 64).toLowerCase();
    if (!mime || !isAllowedImageMime(mime)) fail(ErrorCode.unsupportedImageType, 400);
    const b64 = typeof input.imageBase64 === 'string' ? input.imageBase64.trim() : '';
    if (!b64) fail(ErrorCode.invalidImage, 400);
    const maxB64 = Math.ceil((this.config.maxImageBytes * 4) / 3) + 128;
    if (b64.length > maxB64) fail(ErrorCode.imageTooLarge, 400);
    let bytes: Buffer;
    try {
      bytes = Buffer.from(b64, 'base64');
    } catch {
      fail(ErrorCode.invalidImage, 400);
    }
    if (bytes.length === 0) fail(ErrorCode.invalidImage, 400);
    validateImageBytes(bytes, mime, this.config);
    const contentType = mime === 'image/jpg' ? 'image/jpeg' : mime;
    const ext = extensionForMime(contentType);
    if (!ext) fail(ErrorCode.unsupportedImageType, 400);

    const objectPath = stagedObjectPath({
      readingType,
      ownerUserId: input.ownerUserId,
      operationId: input.operationId,
      ext,
      slot,
    });
    const checksumSha256 = createHash('sha256').update(bytes).digest('hex');

    // Exact-duplicate protection (Coffee V2 only, Phase 2A): the three
    // slots must never carry byte-identical content. Checked before any
    // write for this slot, so a duplicate can never reach 'complete' and
    // can never be seen by the worker/AI. Restaging the SAME slot with the
    // same bytes is exempt by construction (`r.slot !== slot` below) — that
    // is the existing idempotent-restage behavior, not a duplicate.
    if (slot) {
      const others = await this.repository.listSlots(input.operationId, input.ownerUserId);
      const duplicate = others.some(
        (r) => r.slot !== slot && r.uploadState === 'complete' && r.checksumSha256 === checksumSha256,
      );
      if (duplicate) fail(ErrorCode.duplicateStagedImage, 409);
    }

    const createdAtMs = toEpochMs(this.clock.now());
    const pending: ReadingStagedImageRecord = {
      schemaVersion: STAGED_IMAGE_SCHEMA_VERSION,
      operationId: input.operationId,
      ownerUserId: input.ownerUserId,
      readingType,
      objectPath,
      contentType,
      byteSize: bytes.length,
      checksumSha256,
      uploadState: 'pending',
      ...(handSide ? { handSide } : {}),
      ...(slot ? { slot } : {}),
      createdAtMs,
      updatedAtMs: createdAtMs,
    };

    try {
      await this.repository.upsert(pending);
      await this.objects.put(objectPath, bytes, contentType);
      await this.repository.upsert({
        ...pending,
        uploadState: 'complete',
        updatedAtMs: toEpochMs(this.clock.now()),
      });
    } catch {
      // Repository and object-store implementations are transport boundaries.
      // Test doubles (and third-party SDK adapters) need not throw our exact
      // sentinel classes; no storage failure is safe to expose or continue.
      throw new ReadingOperationError('unavailable');
    }

    return {
      operationId: input.operationId,
      staged: true,
      contentType,
      byteSize: bytes.length,
      readyAtMs: operation.readyAtMs,
    };
  }

  /**
   * Requires `uploadState == 'complete'`, re-validates bytes and checksum
   * server-side, and only ever reads the server-owned `objectPath` already
   * on file — never a client-supplied path. Fails closed (never fabricates
   * input) on anything missing, incomplete, or corrupt.
   */
  async retrieveForProcessing(input: {
    ownerUserId: string;
    operationId: string;
    readingType: StagedImageReadingType;
  }): Promise<{ bytes: Buffer; mimeType: string }> {
    const operation = await this.operations.get(input.ownerUserId, input.operationId);
    if (operation.readingType !== input.readingType) {
      throw new ReadingOperationError('not_found');
    }
    let record: ReadingStagedImageRecord | null;
    try {
      record = await this.repository.get(input.operationId, input.ownerUserId);
    } catch {
      throw new ReadingOperationError('unavailable');
    }
    if (!record || record.uploadState !== 'complete') {
      throw new ReadingOperationError('invalid');
    }
    if (record.readingType !== input.readingType) {
      throw new ReadingOperationError('not_found');
    }
    let bytes: Buffer | null;
    try {
      bytes = await this.objects.get(record.objectPath);
    } catch (error) {
      throw new ReadingOperationError('unavailable', error);
    }
    if (!bytes) throw new ReadingOperationError('invalid');
    const checksum = createHash('sha256').update(bytes).digest('hex');
    if (checksum !== record.checksumSha256) throw new ReadingOperationError('invalid');
    validateImageBytes(bytes, record.contentType, this.config);
    return { bytes, mimeType: record.contentType };
  }

  /**
   * Coffee V2 only (Phase 2A). True the moment ANY of the three canonical
   * slots has a record at all (regardless of upload state) — this is the
   * sole signal the processor uses to decide "this is a slotted Coffee V2
   * input" vs. "this is the legacy single-image path" (spec section 6/8).
   * Never true for Palm (no slot records can exist for Palm — `stage()`
   * fails closed before one could ever be written).
   */
  async hasAnyCoffeeV2Slot(input: {
    ownerUserId: string;
    operationId: string;
  }): Promise<boolean> {
    const slots = await this.repository.listSlots(input.operationId, input.ownerUserId);
    return slots.length > 0;
  }

  /**
   * Coffee V2 only (Phase 2A). Requires all three canonical slots present
   * AND `uploadState === 'complete'` — otherwise throws the same
   * `ReadingOperationError('invalid')` the legacy `retrieveForProcessing`
   * throws on an incomplete stage, which the worker already treats as a
   * retryable "staging not ready" condition (never a terminal failure,
   * never an AI call) — see reading-processor-execute.ts. Re-validates
   * bytes and checksum per slot exactly like the legacy path. Returns the
   * three images in canonical order: cup_primary, cup_secondary, saucer.
   */
  async retrieveCoffeeV2ForProcessing(input: {
    ownerUserId: string;
    operationId: string;
  }): Promise<Array<{ slot: CoffeeV2Slot; bytes: Buffer; mimeType: string }>> {
    const operation = await this.operations.get(input.ownerUserId, input.operationId);
    if (operation.readingType !== 'coffee') {
      throw new ReadingOperationError('not_found');
    }
    const out: Array<{ slot: CoffeeV2Slot; bytes: Buffer; mimeType: string }> = [];
    for (const slot of COFFEE_V2_SLOTS) {
      let record: ReadingStagedImageRecord | null;
      try {
        record = await this.repository.getSlot(input.operationId, slot, input.ownerUserId);
      } catch {
        throw new ReadingOperationError('unavailable');
      }
      if (!record || record.uploadState !== 'complete') {
        throw new ReadingOperationError('invalid');
      }
      let bytes: Buffer | null;
      try {
        bytes = await this.objects.get(record.objectPath);
      } catch (error) {
        throw new ReadingOperationError('unavailable', error);
      }
      if (!bytes) throw new ReadingOperationError('invalid');
      const checksum = createHash('sha256').update(bytes).digest('hex');
      if (checksum !== record.checksumSha256) throw new ReadingOperationError('invalid');
      validateImageBytes(bytes, record.contentType, this.config);
      out.push({ slot, bytes, mimeType: record.contentType });
    }
    return out;
  }

  /**
   * Best-effort and idempotent by design: cleanup failure must never throw
   * into a completion/failure path or corrupt an already-persisted result.
   * Never touches another operation's object (ownership is re-checked via
   * the metadata lookup itself).
   */
  async delete(input: { ownerUserId: string; operationId: string }): Promise<void> {
    let record: ReadingStagedImageRecord | null;
    try {
      record = await this.repository.get(input.operationId, input.ownerUserId);
    } catch {
      return;
    }
    if (!record) return;
    try {
      await this.objects.delete(record.objectPath);
    } catch {
      this.onCleanupFailure?.({ event: 'staged_cleanup_failed', operationId: input.operationId, readingType: record.readingType, stage: 'object' });
      // Best-effort — the bucket's own lifecycle rule is the safety net.
    }
    try {
      await this.repository.delete(input.operationId);
    } catch {
      this.onCleanupFailure?.({ event: 'staged_cleanup_failed', operationId: input.operationId, readingType: record.readingType, stage: 'metadata' });
      // Best-effort — safe to retry later; never corrupts a persisted result.
    }
  }

  /**
   * Coffee V2 only (Phase 2B). Deletes all three canonical slots' GCS
   * objects and Firestore records. Best-effort and idempotent per slot,
   * exactly like legacy `delete()` above — a missing slot (already
   * deleted, or never uploaded) is treated as already-clean, never an
   * error, and never blocks deleting the other slots. Never touches
   * another owner's slot (ownership re-checked via each slot's own
   * metadata lookup). Call only after a successfully persisted result —
   * never on a retryable failure, so a restart/retry can still find the
   * staged inputs it needs.
   */
  async deleteCoffeeV2Slots(input: { ownerUserId: string; operationId: string }): Promise<void> {
    for (const slot of COFFEE_V2_SLOTS) {
      let record: ReadingStagedImageRecord | null;
      try {
        record = await this.repository.getSlot(input.operationId, slot, input.ownerUserId);
      } catch {
        continue;
      }
      if (!record) continue;
      try {
        await this.objects.delete(record.objectPath);
      } catch {
        this.onCleanupFailure?.({ event: 'staged_cleanup_failed', operationId: input.operationId, readingType: record.readingType, stage: 'object' });
        // Best-effort — the bucket's own lifecycle rule is the safety net.
      }
      try {
        await this.repository.deleteSlot(input.operationId, slot);
      } catch {
        this.onCleanupFailure?.({ event: 'staged_cleanup_failed', operationId: input.operationId, readingType: record.readingType, stage: 'metadata' });
        // Best-effort — safe to retry later; never corrupts a persisted result.
      }
    }
  }
}

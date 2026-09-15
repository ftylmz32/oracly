/**
 * Owner- and operation-checked access to a ReadingOperation's structured
 * input (BATCH 5G). Every call cross-validates against the real
 * ReadingOperation (via ReadingOperationService.get, which is already
 * owner-checked) before touching input storage — an input row can never
 * be read or written for an operation the caller does not own, and it can
 * never be attached to an operation that does not exist.
 */
import type { ServerClock } from './clock.js';
import { toEpochMs } from './clock.js';
import {
  INPUT_SCHEMA_VERSION,
  sanitizeSoulmateFields,
  type SoulmateInputFields,
} from './operation-input-model.js';
import {
  ReadingInputStorageUnavailable,
  type ReadingOperationInputRepository,
} from './operation-input-repository.js';
import { ReadingOperationError, type ReadingOperationService } from './operation-service.js';

export class ReadingOperationInputService {
  constructor(
    private readonly repository: ReadingOperationInputRepository,
    private readonly operations: ReadingOperationService,
    private readonly clock: ServerClock,
  ) {}

  async save(input: {
    ownerUserId: string;
    operationId: string;
    fields: unknown;
  }): Promise<void> {
    const fields = sanitizeSoulmateFields(input.fields);
    if (!fields) throw new ReadingOperationError('invalid');
    const operation = await this.operations.get(input.ownerUserId, input.operationId);
    const nowMs = toEpochMs(this.clock.now());
    try {
      await this.repository.upsert({
        schemaVersion: INPUT_SCHEMA_VERSION,
        operationId: operation.operationId,
        ownerUserId: input.ownerUserId,
        readingType: operation.readingType,
        createdAtMs: nowMs,
        updatedAtMs: nowMs,
        fields,
      });
    } catch (error) {
      if (error instanceof ReadingInputStorageUnavailable) {
        throw new ReadingOperationError('unavailable');
      }
      throw error;
    }
  }

  async get(
    ownerUserId: string,
    operationId: string,
  ): Promise<SoulmateInputFields | null> {
    await this.operations.get(ownerUserId, operationId);
    try {
      const record = await this.repository.get(operationId, ownerUserId);
      return record?.fields ?? null;
    } catch (error) {
      if (error instanceof ReadingInputStorageUnavailable) {
        throw new ReadingOperationError('unavailable');
      }
      throw error;
    }
  }
}

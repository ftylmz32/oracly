/**
 * BATCH 5I — narrow storage abstraction for durable Coffee/Palm image
 * staging. GCS SDK types never leak past this file.
 *
 * Downloads use a single file.download() call — never exists()+download()
 * on the same File, which stacked PassThrough listeners on shared Storage
 * clients under Cloud Tasks retry pressure.
 */
import { Storage } from '@google-cloud/storage';
import type { AppConfig } from '../config.js';

export class StagedObjectStorageUnavailable extends Error {
  constructor(message = 'staged_object_storage_unavailable', cause?: unknown) {
    super(message, cause instanceof Error ? { cause } : undefined);
    this.name = 'StagedObjectStorageUnavailable';
  }
}

export interface ReadingStagedObjectStore {
  put(objectPath: string, bytes: Buffer, contentType: string): Promise<void>;
  get(objectPath: string): Promise<Buffer | null>;
  delete(objectPath: string): Promise<void>;
}

export class GcsReadingStagedObjectStore implements ReadingStagedObjectStore {
  constructor(
    private readonly bucketName: string,
    private readonly storage: Storage,
  ) {}

  async put(objectPath: string, bytes: Buffer, contentType: string): Promise<void> {
    try {
      await this.storage
        .bucket(this.bucketName)
        .file(objectPath)
        .save(bytes, { contentType, resumable: false });
    } catch (error) {
      throw new StagedObjectStorageUnavailable(
        gcsSafeMessage(error, 'staged_object_put_failed'),
        error,
      );
    }
  }

  async get(objectPath: string): Promise<Buffer | null> {
    try {
      const [bytes] = await this.storage
        .bucket(this.bucketName)
        .file(objectPath)
        .download();
      return bytes;
    } catch (error) {
      if (isNotFound(error)) return null;
      throw new StagedObjectStorageUnavailable(
        gcsSafeMessage(error, 'staged_object_get_failed'),
        error,
      );
    }
  }

  async delete(objectPath: string): Promise<void> {
    try {
      await this.storage
        .bucket(this.bucketName)
        .file(objectPath)
        .delete({ ignoreNotFound: true });
    } catch (error) {
      throw new StagedObjectStorageUnavailable(
        gcsSafeMessage(error, 'staged_object_delete_failed'),
        error,
      );
    }
  }
}

export class FailClosedReadingStagedObjectStore implements ReadingStagedObjectStore {
  async put(): Promise<void> {
    throw new StagedObjectStorageUnavailable('staged_object_storage_unavailable');
  }

  async get(): Promise<Buffer | null> {
    throw new StagedObjectStorageUnavailable('staged_object_storage_unavailable');
  }

  async delete(): Promise<void> {
    throw new StagedObjectStorageUnavailable('staged_object_storage_unavailable');
  }
}

let sharedStorage: Storage | null = null;

export function createReadingStagedObjectStore(config: AppConfig): ReadingStagedObjectStore {
  if (!config.readingStagingBucket) {
    return new FailClosedReadingStagedObjectStore();
  }
  try {
    sharedStorage ??= new Storage({ projectId: config.firebaseProjectId ?? undefined });
    return new GcsReadingStagedObjectStore(config.readingStagingBucket, sharedStorage);
  } catch {
    return new FailClosedReadingStagedObjectStore();
  }
}

function isNotFound(error: unknown): boolean {
  const code = (error as { code?: number | string }).code;
  return code === 404 || code === '404' || code === 'ENOENT';
}

function gcsSafeMessage(error: unknown, fallback: string): string {
  if (!(error instanceof Error) || !error.message) return fallback;
  return error.message
    .replace(/Bearer\s+\S+/gi, '[redacted]')
    .replace(/sk-[a-zA-Z0-9_-]{8,}/g, '[redacted]')
    .slice(0, 160);
}

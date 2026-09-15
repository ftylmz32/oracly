/**
 * In-memory stand-in for `ReadingStagedObjectStore` — tests only. Mirrors
 * `memory-document-store.ts`'s role for Firestore: the real service class
 * runs unmodified against this fake; only the storage transport is faked.
 */
import type { ReadingStagedObjectStore } from './staged-object-store.js';

export class MemoryStagedObjectStore implements ReadingStagedObjectStore {
  readonly objects = new Map<string, { bytes: Buffer; contentType: string }>();

  async put(objectPath: string, bytes: Buffer, contentType: string): Promise<void> {
    this.objects.set(objectPath, { bytes: Buffer.from(bytes), contentType });
  }

  async get(objectPath: string): Promise<Buffer | null> {
    const found = this.objects.get(objectPath);
    return found ? Buffer.from(found.bytes) : null;
  }

  async delete(objectPath: string): Promise<void> {
    this.objects.delete(objectPath);
  }
}

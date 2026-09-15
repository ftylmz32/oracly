import { describe, expect, it, vi } from 'vitest';
import {
  GcsReadingStagedObjectStore,
  StagedObjectStorageUnavailable,
} from '../src/reading/staged-object-store.js';

describe('GcsReadingStagedObjectStore stream lifecycle', () => {
  it('downloads once via file.download without a prior exists() call', async () => {
    const download = vi.fn(async () => [Buffer.from('abc')]);
    const exists = vi.fn();
    const file = vi.fn(() => ({ download, exists }));
    const bucket = vi.fn(() => ({ file }));
    const storage = { bucket } as never;
    const store = new GcsReadingStagedObjectStore('bucket', storage);
    const bytes = await store.get('path/input.jpg');
    expect(bytes?.equals(Buffer.from('abc'))).toBe(true);
    expect(download).toHaveBeenCalledOnce();
    expect(exists).not.toHaveBeenCalled();
  });

  it('preserves the original GCS error as cause on failure', async () => {
    const original = Object.assign(new Error('stream_broken'), { code: 500 });
    const download = vi.fn(async () => {
      throw original;
    });
    const file = vi.fn(() => ({ download }));
    const bucket = vi.fn(() => ({ file }));
    const storage = { bucket } as never;
    const store = new GcsReadingStagedObjectStore('bucket', storage);
    await expect(store.get('path/input.jpg')).rejects.toMatchObject({
      name: 'StagedObjectStorageUnavailable',
      cause: original,
    });
    expect(StagedObjectStorageUnavailable).toBeTruthy();
  });
});

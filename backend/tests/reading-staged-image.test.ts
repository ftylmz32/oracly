import { describe, expect, it } from 'vitest';
import { fakeJpeg, testConfig } from './helpers.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import {
  extensionForMime,
  stagedObjectPath,
} from '../src/reading/operation-staged-image-model.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationError, ReadingOperationService } from '../src/reading/operation-service.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

function fakePng(bytes = 9000): Buffer {
  const buf = Buffer.alloc(bytes, 0x41);
  buf[0] = 0x89;
  buf[1] = 0x50;
  buf[2] = 0x4e;
  buf[3] = 0x47;
  return buf;
}

function fakeWebp(bytes = 9000): Buffer {
  const buf = Buffer.alloc(bytes, 0x41);
  buf.write('RIFF', 0, 'ascii');
  buf.write('WEBP', 8, 'ascii');
  return buf;
}

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'));
  const policy = provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 });
  const operationRepository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(operationRepository, clock, policy);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const objects = new MemoryStagedObjectStore();
  const config = testConfig();
  const service = new ReadingStagedImageService(
    stagedRepository,
    objects,
    operations,
    clock,
    config,
  );
  return { store, clock, operations, stagedRepository, objects, config, service };
}

async function coffeeOp(h: ReturnType<typeof harness>, owner = 'owner-a') {
  return h.operations.create({
    ownerUserId: owner,
    readingType: 'coffee',
    sourceRequestId: `req-${owner}-${Math.random().toString(36).slice(2)}`,
  });
}

async function palmOp(h: ReturnType<typeof harness>, owner = 'owner-a') {
  return h.operations.create({
    ownerUserId: owner,
    readingType: 'palm',
    sourceRequestId: `req-palm-${owner}-${Math.random().toString(36).slice(2)}`,
  });
}

describe('operation-staged-image-model', () => {
  it('derives extension only from validated MIME', () => {
    expect(extensionForMime('image/jpeg')).toBe('jpg');
    expect(extensionForMime('image/jpg')).toBe('jpg');
    expect(extensionForMime('image/png')).toBe('png');
    expect(extensionForMime('image/webp')).toBe('webp');
    expect(extensionForMime('image/gif')).toBeNull();
  });

  it('builds an owner/operation/reading-type scoped path with a path-safe owner key', () => {
    const path = stagedObjectPath({
      readingType: 'coffee',
      ownerUserId: 'sub:abcdef0123456789',
      operationId: 'op-1234567890',
      ext: 'jpg',
    });
    expect(path).toBe('reading-staging/coffee/sub_abcdef0123456789/op-1234567890/input.jpg');
  });
});

describe('ReadingStagedImageService.stage', () => {
  it('A stages a valid JPEG end to end', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakeJpeg();
    const status = await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: bytes.toString('base64'),
    });
    expect(status).toEqual({
      operationId: op.operationId,
      staged: true,
      contentType: 'image/jpeg',
      byteSize: bytes.length,
      readyAtMs: op.readyAtMs,
    });
  });

  it('B stages a valid PNG end to end', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakePng();
    const status = await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/png',
      imageBase64: bytes.toString('base64'),
    });
    expect(status.contentType).toBe('image/png');
  });

  it('C stages a valid WEBP end to end', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakeWebp();
    const status = await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/webp',
      imageBase64: bytes.toString('base64'),
    });
    expect(status.contentType).toBe('image/webp');
  });

  it('D rejects an invalid/unsupported MIME type', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/gif',
        imageBase64: fakeJpeg().toString('base64'),
      }),
    ).rejects.toMatchObject({ code: 'unsupported_image_type' });
  });

  it('E rejects a magic-byte/MIME mismatch (claimed JPEG, actually PNG bytes)', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakePng().toString('base64'),
      }),
    ).rejects.toMatchObject({ code: 'invalid_image' });
  });

  it('F rejects an oversized image', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(h.config.maxImageBytes + 1024).toString('base64'),
      }),
    ).rejects.toMatchObject({ code: 'image_too_large' });
  });

  it('rejects an undersized image', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg(1024).toString('base64'),
      }),
    ).rejects.toMatchObject({ code: 'invalid_image' });
  });

  it('G rejects staging for an operation owned by someone else', async () => {
    const h = harness();
    const op = await coffeeOp(h, 'owner-a');
    await expect(
      h.service.stage({
        ownerUserId: 'owner-b',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
      }),
    ).rejects.toMatchObject({ code: 'not_found' });
  });

  it('H rejects staging for a non coffee/palm operation (soulmate)', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-soulmate-1',
    });
    await expect(
      h.service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
      }),
    ).rejects.toMatchObject({ code: 'not_found' });
  });

  it('I duplicate stage for the same operation is idempotent (overwrites, no duplicate object)', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const first = fakeJpeg(9000);
    const second = fakeJpeg(9500);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: first.toString('base64'),
    });
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: second.toString('base64'),
    });
    expect(h.objects.objects.size).toBe(1);
    const record = await h.stagedRepository.get(op.operationId, 'owner-a');
    expect(record?.byteSize).toBe(second.length);
  });

  it('J metadata is pending until the object write succeeds, then flips to complete', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    const record = await h.stagedRepository.get(op.operationId, 'owner-a');
    expect(record?.uploadState).toBe('complete');
  });

  it('K a failed object write never marks the metadata complete', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const failingObjects = {
      put: async () => {
        throw new Error('simulated gcs failure');
      },
      get: async () => null,
      delete: async () => {},
    };
    const service = new ReadingStagedImageService(
      h.stagedRepository,
      failingObjects,
      h.operations,
      h.clock,
      h.config,
    );
    await expect(
      service.stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
      }),
    ).rejects.toMatchObject({ code: 'unavailable' });
    const record = await h.stagedRepository.get(op.operationId, 'owner-a');
    expect(record?.uploadState).toBe('pending');
  });
});

describe('ReadingStagedImageService.retrieveForProcessing', () => {
  it('L a complete object retrieves the exact bytes', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const bytes = fakeJpeg();
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: bytes.toString('base64'),
    });
    const result = await h.service.retrieveForProcessing({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      readingType: 'coffee',
    });
    expect(result.mimeType).toBe('image/jpeg');
    expect(Buffer.compare(result.bytes, bytes)).toBe(0);
  });

  it('M a corrupt stored object (checksum mismatch) fails validation', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    const record = await h.stagedRepository.get(op.operationId, 'owner-a');
    await h.objects.put(record!.objectPath, fakeJpeg(9500), 'image/jpeg');
    await expect(
      h.service.retrieveForProcessing({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        readingType: 'coffee',
      }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });

  it('N a missing object fails closed (never fabricates input)', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    const record = await h.stagedRepository.get(op.operationId, 'owner-a');
    await h.objects.delete(record!.objectPath);
    await expect(
      h.service.retrieveForProcessing({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        readingType: 'coffee',
      }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });

  it('refuses retrieval while upload is still pending', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    const failingObjects = {
      put: async () => {
        throw new Error('simulated gcs failure');
      },
      get: async () => null,
      delete: async () => {},
    };
    const service = new ReadingStagedImageService(
      h.stagedRepository,
      failingObjects,
      h.operations,
      h.clock,
      h.config,
    );
    await service
      .stage({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        mimeType: 'image/jpeg',
        imageBase64: fakeJpeg().toString('base64'),
      })
      .catch(() => {});
    await expect(
      h.service.retrieveForProcessing({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        readingType: 'coffee',
      }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });

  it('rejects retrieval for the wrong owner', async () => {
    const h = harness();
    const op = await coffeeOp(h, 'owner-a');
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    await expect(
      h.service.retrieveForProcessing({
        ownerUserId: 'owner-b',
        operationId: op.operationId,
        readingType: 'coffee',
      }),
    ).rejects.toBeInstanceOf(ReadingOperationError);
  });

  it('rejects retrieval for the wrong readingType', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    await expect(
      h.service.retrieveForProcessing({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        readingType: 'palm',
      }),
    ).rejects.toMatchObject({ code: 'not_found' });
  });

  it('supports palm operations identically to coffee', async () => {
    const h = harness();
    const op = await palmOp(h);
    const bytes = fakeJpeg();
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: bytes.toString('base64'),
      handSide: 'right',
    });
    const result = await h.service.retrieveForProcessing({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      readingType: 'palm',
    });
    expect(Buffer.compare(result.bytes, bytes)).toBe(0);
  });
});

describe('ReadingStagedImageService.delete', () => {
  it('O delete is idempotent', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    await h.service.delete({ ownerUserId: 'owner-a', operationId: op.operationId });
    await expect(
      h.service.delete({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).resolves.toBeUndefined();
    expect(await h.stagedRepository.get(op.operationId, 'owner-a')).toBeNull();
    expect(h.objects.objects.size).toBe(0);
  });

  it('never deletes another owner\'s staged object', async () => {
    const h = harness();
    const opA = await coffeeOp(h, 'owner-a');
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: opA.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    await h.service.delete({ ownerUserId: 'owner-b', operationId: opA.operationId });
    // Wrong-owner delete is a safe no-op — the real object survives.
    expect(h.objects.objects.size).toBe(1);
    expect(await h.stagedRepository.get(opA.operationId, 'owner-a')).not.toBeNull();
  });

  it('delete never throws even if the object store fails', async () => {
    const h = harness();
    const op = await coffeeOp(h);
    await h.service.stage({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      mimeType: 'image/jpeg',
      imageBase64: fakeJpeg().toString('base64'),
    });
    const failingObjects = {
      put: async () => {},
      get: async () => null,
      delete: async () => {
        throw new Error('simulated gcs failure');
      },
    };
    const service = new ReadingStagedImageService(
      h.stagedRepository,
      failingObjects,
      h.operations,
      h.clock,
      h.config,
    );
    await expect(
      service.delete({ ownerUserId: 'owner-a', operationId: op.operationId }),
    ).resolves.toBeUndefined();
  });
});

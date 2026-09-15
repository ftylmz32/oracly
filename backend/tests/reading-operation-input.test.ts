import { describe, expect, it } from 'vitest';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import {
  sanitizeSoulmateFields,
  parseStoredInputRecord,
  toStoredInputDocument,
  INPUT_SCHEMA_VERSION,
} from '../src/reading/operation-input-model.js';
import {
  FailClosedReadingOperationInputRepository,
  FirestoreReadingOperationInputRepository,
} from '../src/reading/operation-input-repository.js';
import { ReadingOperationInputService } from '../src/reading/operation-input-service.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationError, ReadingOperationService } from '../src/reading/operation-service.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

describe('sanitizeSoulmateFields', () => {
  it('accepts a minimal valid payload', () => {
    expect(sanitizeSoulmateFields({ name: 'Ayse', birthIso: '1991-04-02' })).toEqual({
      name: 'Ayse',
      birthIso: '1991-04-02',
    });
  });

  it('rejects unknown keys outright', () => {
    expect(
      sanitizeSoulmateFields({ name: 'Ayse', birthIso: '1991-04-02', extra: 'x' }),
    ).toBeNull();
  });

  it('rejects a missing required field', () => {
    expect(sanitizeSoulmateFields({ name: 'Ayse' })).toBeNull();
    expect(sanitizeSoulmateFields({ birthIso: '1991-04-02' })).toBeNull();
  });

  it('rejects a malformed birth date', () => {
    expect(
      sanitizeSoulmateFields({ name: 'Ayse', birthIso: '04/02/1991' }),
    ).toBeNull();
    expect(
      sanitizeSoulmateFields({ name: 'Ayse', birthIso: '1991-4-2' }),
    ).toBeNull();
  });

  it('rejects an oversized field', () => {
    expect(
      sanitizeSoulmateFields({ name: 'a'.repeat(61), birthIso: '1991-04-02' }),
    ).toBeNull();
    expect(
      sanitizeSoulmateFields({
        name: 'Ayse',
        birthIso: '1991-04-02',
        intention: 'a'.repeat(201),
      }),
    ).toBeNull();
  });

  it('rejects an invalid gender value', () => {
    expect(
      sanitizeSoulmateFields({
        name: 'Ayse',
        birthIso: '1991-04-02',
        gender: 'other',
      }),
    ).toBeNull();
  });

  it('accepts a full valid payload and trims whitespace', () => {
    expect(
      sanitizeSoulmateFields({
        name: '  Ayse  ',
        birthIso: '1991-04-02',
        gender: 'feminine',
        intention: '  calm  ',
      }),
    ).toEqual({
      name: 'Ayse',
      birthIso: '1991-04-02',
      gender: 'feminine',
      intention: 'calm',
    });
  });

  it('rejects a non-string value', () => {
    expect(
      sanitizeSoulmateFields({ name: 123, birthIso: '1991-04-02' }),
    ).toBeNull();
  });
});

describe('operation-input-model round trip', () => {
  it('parses what it stores', () => {
    const record = {
      schemaVersion: INPUT_SCHEMA_VERSION,
      operationId: 'op-1234567890',
      ownerUserId: 'sub:abcdefgh',
      readingType: 'soulmate' as const,
      createdAtMs: 1000,
      updatedAtMs: 2000,
      fields: { name: 'Ayse', birthIso: '1991-04-02' },
    };
    expect(parseStoredInputRecord(toStoredInputDocument(record))).toEqual(record);
  });

  it('rejects a wrong schema version', () => {
    expect(
      parseStoredInputRecord({
        schemaVersion: 2,
        operationId: 'op-1234567890',
        ownerUserId: 'sub:abcdefgh',
        readingType: 'soulmate',
        createdAtMs: 1,
        updatedAtMs: 1,
        fields: { name: 'Ayse', birthIso: '1991-04-02' },
      }),
    ).toBeNull();
  });
});

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'));
  const policy = provisionalWaitPolicy({ soulmate: 1_000 });
  const operationRepository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(operationRepository, clock, policy);
  const inputRepository = new FirestoreReadingOperationInputRepository(store);
  const service = new ReadingOperationInputService(inputRepository, operations, clock);
  return { store, clock, policy, operations, service, inputRepository, operationRepository };
}

describe('ReadingOperationInputService', () => {
  it('saves and reads back input for the owning user', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-1',
    });
    await h.service.save({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      fields: { name: 'Ayse', birthIso: '1991-04-02' },
    });
    const fields = await h.service.get('owner-a', op.operationId);
    expect(fields).toEqual({ name: 'Ayse', birthIso: '1991-04-02' });
  });

  it('rejects save for an operation the caller does not own', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-1',
    });
    await expect(
      h.service.save({
        ownerUserId: 'owner-b',
        operationId: op.operationId,
        fields: { name: 'Ayse', birthIso: '1991-04-02' },
      }),
    ).rejects.toBeInstanceOf(ReadingOperationError);
  });

  it('rejects read for an operation the caller does not own', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-1',
    });
    await h.service.save({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      fields: { name: 'Ayse', birthIso: '1991-04-02' },
    });
    await expect(h.service.get('owner-b', op.operationId)).rejects.toBeInstanceOf(
      ReadingOperationError,
    );
  });

  it('rejects save against a nonexistent operation', async () => {
    const h = harness();
    await expect(
      h.service.save({
        ownerUserId: 'owner-a',
        operationId: 'does-not-exist',
        fields: { name: 'Ayse', birthIso: '1991-04-02' },
      }),
    ).rejects.toBeInstanceOf(ReadingOperationError);
  });

  it('rejects invalid fields before touching storage', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-1',
    });
    await expect(
      h.service.save({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        fields: { name: 'Ayse' },
      }),
    ).rejects.toMatchObject({ code: 'invalid' });
  });

  it('returns null when no input has been saved yet', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-1',
    });
    expect(await h.service.get('owner-a', op.operationId)).toBeNull();
  });

  it('upsert overwrites the previous fields for the same operation', async () => {
    const h = harness();
    const op = await h.operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-1',
    });
    await h.service.save({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      fields: { name: 'Ayse', birthIso: '1991-04-02' },
    });
    await h.service.save({
      ownerUserId: 'owner-a',
      operationId: op.operationId,
      fields: { name: 'Ayse', birthIso: '1991-04-02', intention: 'calm' },
    });
    expect(await h.service.get('owner-a', op.operationId)).toEqual({
      name: 'Ayse',
      birthIso: '1991-04-02',
      intention: 'calm',
    });
  });

  it('fails closed when input storage is unavailable', async () => {
    const store = new MemoryDocumentStore();
    const clock = new FixedClock(1);
    const policy = provisionalWaitPolicy({ soulmate: 1_000 });
    const operationRepository = new FirestoreReadingOperationRepository(store);
    const operations = new ReadingOperationService(operationRepository, clock, policy);
    const service = new ReadingOperationInputService(
      new FailClosedReadingOperationInputRepository(),
      operations,
      clock,
    );
    const op = await operations.create({
      ownerUserId: 'owner-a',
      readingType: 'soulmate',
      sourceRequestId: 'req-1',
    });
    await expect(
      service.save({
        ownerUserId: 'owner-a',
        operationId: op.operationId,
        fields: { name: 'Ayse', birthIso: '1991-04-02' },
      }),
    ).rejects.toMatchObject({ code: 'unavailable' });
    await expect(service.get('owner-a', op.operationId)).rejects.toMatchObject({
      code: 'unavailable',
    });
  });
});

function headers(sub: string) {
  return {
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
  };
}

describe('reading-operation-input routes', () => {
  async function appFor() {
    const h = harness();
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      async () => {
        throw new Error('input routes must not call the AI provider');
      },
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingOperationRepository: h.operationRepository,
        readingClock: h.clock,
        readingWaitPolicy: h.policy,
        readingOperationInputRepository: h.inputRepository,
      },
    );
    return { app, ...h };
  }

  // Operations are created over HTTP (not via operations.create() directly)
  // so ownerUserId is the real hashed identityKey the auth middleware
  // derives from the JWT sub — matching what the input routes compare
  // against, exactly like reading-operations.test.ts's own createOp helper.
  async function createOp(app: Awaited<ReturnType<typeof appFor>>['app'], sub: string) {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(sub),
      payload: { readingType: 'soulmate', sourceRequestId: `req-${sub}` },
    });
    return res.json().data.operationId as string;
  }

  it('saves then reads structured input for the owner', async () => {
    const { app } = await appFor();
    const operationId = await createOp(app, 'user-a');
    const put = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${operationId}/input`,
      headers: headers('user-a'),
      payload: { name: 'Ayse', birthIso: '1991-04-02' },
    });
    expect(put.statusCode).toBe(200);

    const get = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${operationId}/input`,
      headers: headers('user-a'),
    });
    expect(get.statusCode).toBe(200);
    expect(get.json().data.fields).toEqual({ name: 'Ayse', birthIso: '1991-04-02' });
    await app.close();
  });

  it('rejects a request from a different owner with 404', async () => {
    const { app } = await appFor();
    const operationId = await createOp(app, 'user-a');
    const put = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${operationId}/input`,
      headers: headers('user-b'),
      payload: { name: 'Ayse', birthIso: '1991-04-02' },
    });
    expect(put.statusCode).toBe(404);
    await app.close();
  });

  it('rejects an invalid body with 400', async () => {
    const { app } = await appFor();
    const operationId = await createOp(app, 'user-a');
    const put = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${operationId}/input`,
      headers: headers('user-a'),
      payload: { name: 'Ayse', birthIso: '1991-04-02', secret: 'nope' },
    });
    expect(put.statusCode).toBe(400);
    await app.close();
  });

  it('returns 404 for a nonexistent operation', async () => {
    const { app } = await appFor();
    const put = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations/does-not-exist/input',
      headers: headers('user-a'),
      payload: { name: 'Ayse', birthIso: '1991-04-02' },
    });
    expect(put.statusCode).toBe(404);
    await app.close();
  });

  it('returns null fields for an operation with no saved input yet', async () => {
    const { app } = await appFor();
    const operationId = await createOp(app, 'user-a');
    const get = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${operationId}/input`,
      headers: headers('user-a'),
    });
    expect(get.statusCode).toBe(200);
    expect(get.json().data.fields).toBeNull();
    await app.close();
  });

  it('requires authentication', async () => {
    const { app } = await appFor();
    const operationId = await createOp(app, 'user-a');
    const get = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${operationId}/input`,
      headers: appCheckHeader('good-token'),
    });
    expect(get.statusCode).toBe(401);
    await app.close();
  });
});

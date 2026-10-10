/**
 * LIS1 — Coffee V3 four-view staging contract + immutable operation
 * discriminator. DARK foundation: the public create route refuses the field,
 * and no worker / pipeline / gem path dispatches on it. Zero provider calls.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import {
  COFFEE_CAPTURE_CONTRACTS,
  isCoffeeCaptureContract,
  parseStoredRecord,
  toStoredDocument,
} from '../src/reading/operation-model.js';
import { FirestoreReadingOperationRepository, idempotencyKeyFor } from '../src/reading/operation-repository.js';
import { ReadingOperationError, ReadingOperationService } from '../src/reading/operation-service.js';
import {
  COFFEE_V2_SLOTS,
  COFFEE_V3_STAGED_SLOTS,
  parseStoredStagedImageRecord,
  stagedDocId,
  stagedObjectPath,
  toStoredStagedImageDocument,
  type ReadingStagedImageRecord,
} from '../src/reading/operation-staged-image-model.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  fakeJpeg,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const OWNER = 'owner-a';
const INTENTION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const V3 = ['v3_cup_handle_far', 'v3_cup_turn_a', 'v3_cup_turn_b', 'v3_saucer'] as const;

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-10T00:00:00.000Z'));
  const policy = provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 });
  const operationRepository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(operationRepository, clock, policy);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const objects = new MemoryStagedObjectStore();
  const service = new ReadingStagedImageService(stagedRepository, objects, operations, clock, testConfig());
  return { store, clock, operationRepository, operations, stagedRepository, objects, service };
}

let seq = 0;
const source = (tag: string) => `req-lis1-${tag}-${(seq += 1)}`;

function v3Op(h: ReturnType<typeof harness>, owner = OWNER, sourceRequestId = source('v3')) {
  return h.operations.create({
    ownerUserId: owner,
    readingType: 'coffee',
    sourceRequestId,
    coffeeInputContract: 'trusted_intention_v1',
    coffeeIntention: INTENTION,
    coffeeCaptureContract: 'four_view_v3',
  });
}
function v2Op(h: ReturnType<typeof harness>, owner = OWNER) {
  return h.operations.create({ ownerUserId: owner, readingType: 'coffee', sourceRequestId: source('v2') });
}
function stage(h: ReturnType<typeof harness>, operationId: string, slot: unknown, bytes: Buffer, owner = OWNER) {
  return h.service.stage({
    ownerUserId: owner,
    operationId,
    mimeType: 'image/jpeg',
    imageBase64: bytes.toString('base64'),
    ...(slot === undefined ? {} : { slot }),
  });
}
async function stageAllV3(h: ReturnType<typeof harness>, operationId: string) {
  for (const [i, slot] of V3.entries()) await stage(h, operationId, slot, fakeJpeg(12000 + i * 100));
}
const errCode = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (error) {
    return error instanceof ReadingOperationError ? error.code : (error as { code?: string }).code ?? String(error);
  }
};

// ---------------------------------------------------------------------------

describe('LIS1 operation capture contract (A–K)', () => {
  const base = (extra: Record<string, unknown> = {}) => ({
    schemaVersion: 1,
    operationId: 'a'.repeat(32),
    ownerUserId: OWNER,
    readingType: 'coffee',
    language: 'tr',
    status: 'waiting',
    createdAtMs: 1,
    readyAtMs: 2,
    updatedAtMs: 1,
    sourceRequestId: 'req-hist-001',
    resultId: null,
    failureCode: null,
    acceleratedAtMs: null,
    gemDebitId: null,
    executionStartedAtMs: null,
    executionMode: null,
    coffeeIntention: null,
    coffeeInputContract: null,
    ...extra,
  });

  it('A: a historical record without the field parses to null and re-stores byte-identically', () => {
    const hist = base();
    const parsed = parseStoredRecord(hist)!;
    expect(parsed.coffeeCaptureContract).toBeNull();
    // A waiting record has no expiresAt, so the round trip is exactly the historical document.
    expect(toStoredDocument(parsed)).toEqual(hist);
    expect('coffeeCaptureContract' in toStoredDocument(parsed)).toBe(false);
    expect(parseStoredRecord(base({ coffeeCaptureContract: null }))!.coffeeCaptureContract).toBeNull();
  });

  it('B: four_view_v3 stores and parses', () => {
    const rec = parseStoredRecord(base({ coffeeInputContract: 'trusted_intention_v1', coffeeIntention: INTENTION, coffeeCaptureContract: 'four_view_v3' }))!;
    expect(rec.coffeeCaptureContract).toBe('four_view_v3');
    expect(toStoredDocument(rec).coffeeCaptureContract).toBe('four_view_v3');
    expect(parseStoredRecord(toStoredDocument(rec) as Record<string, unknown>)!.coffeeCaptureContract).toBe('four_view_v3');
    expect(COFFEE_CAPTURE_CONTRACTS).toEqual(['four_view_v3']);
    expect(isCoffeeCaptureContract('four_view_v3')).toBe(true);
  });

  it('C/D/E: an unknown value, or any value on Palm / Soulmate, fails closed', () => {
    expect(parseStoredRecord(base({ coffeeCaptureContract: 'three_view_v2' }))).toBeNull();
    expect(parseStoredRecord(base({ coffeeCaptureContract: 4 }))).toBeNull();
    expect(parseStoredRecord(base({ readingType: 'palm', coffeeCaptureContract: 'four_view_v3' }))).toBeNull();
    expect(parseStoredRecord(base({ readingType: 'soulmate', coffeeCaptureContract: 'four_view_v3' }))).toBeNull();
  });

  it('D/E/F (service): V3 requires Coffee + trusted_intention_v1 + a valid intention', async () => {
    const h = harness();
    for (const readingType of ['palm', 'soulmate'] as const) {
      expect(await errCode(h.operations.create({ ownerUserId: OWNER, readingType, sourceRequestId: source('x'), coffeeCaptureContract: 'four_view_v3' }))).toBe('invalid');
    }
    expect(await errCode(h.operations.create({ ownerUserId: OWNER, readingType: 'coffee', sourceRequestId: source('x'), coffeeCaptureContract: 'four_view_v3' }))).toBe('invalid');
    expect(await errCode(h.operations.create({ ownerUserId: OWNER, readingType: 'coffee', sourceRequestId: source('x'), coffeeInputContract: 'trusted_intention_v1', coffeeIntention: '   ', coffeeCaptureContract: 'four_view_v3' }))).toBe('invalid');
    const op = await v3Op(h);
    expect(op).toMatchObject({ readingType: 'coffee', coffeeInputContract: 'trusted_intention_v1', coffeeCaptureContract: 'four_view_v3' });
    expect((await h.operationRepository.getById(op.operationId))!.coffeeCaptureContract).toBe('four_view_v3');
  });

  it('G/H/I: same sourceRequestId is idempotent only with the same contract', async () => {
    const h = harness();
    const id = source('idem');
    const a = await v3Op(h, OWNER, id);
    const b = await v3Op(h, OWNER, id);
    expect(b.operationId).toBe(a.operationId);
    const marked = { ownerUserId: OWNER, readingType: 'coffee' as const, coffeeInputContract: 'trusted_intention_v1' as const, coffeeIntention: INTENTION };
    expect(await errCode(h.operations.create({ ...marked, sourceRequestId: id }))).toBe('conflict');
    const nullFirst = source('idem-null');
    await h.operations.create({ ...marked, sourceRequestId: nullFirst });
    expect(await errCode(v3Op(h, OWNER, nullFirst))).toBe('conflict');
  });

  it('J: the idempotency key is unchanged and ignores the capture contract', () => {
    const k = { ownerUserId: OWNER, readingType: 'coffee' as const, sourceRequestId: 'req-key-0001' };
    expect(idempotencyKeyFor({ ...k, coffeeCaptureContract: 'four_view_v3' } as typeof k)).toBe(idempotencyKeyFor(k));
    expect(idempotencyKeyFor(k)).toBe(`${OWNER}\0coffee\0req-key-0001`);
  });

  it('K: V2 / legacy Coffee create semantics are unchanged (contract null, field never stored)', async () => {
    const h = harness();
    const legacy = await v2Op(h);
    const marked = await h.operations.create({ ownerUserId: OWNER, readingType: 'coffee', sourceRequestId: source('m'), coffeeInputContract: 'trusted_intention_v1', coffeeIntention: INTENTION });
    for (const op of [legacy, marked]) {
      expect(op.coffeeCaptureContract).toBeNull();
      const doc = [...h.store.docs.entries()].find(([p]) => p.endsWith(op.operationId))![1] as { data?: Record<string, unknown> } & Record<string, unknown>;
      expect(JSON.stringify(doc)).not.toContain('coffeeCaptureContract');
    }
  });

  it('the contract is immutable across lifecycle mutations', async () => {
    const h = harness();
    const op = await v3Op(h);
    const failed = await h.operations.fail({ ownerUserId: OWNER, operationId: op.operationId, failureCode: 'unavailable' });
    expect(failed.coffeeCaptureContract).toBe('four_view_v3');
    expect((await h.operationRepository.getById(op.operationId))!.coffeeCaptureContract).toBe('four_view_v3');
  });
});

describe('LIS1 public create route stays dark (L–Q)', () => {
  const SECRET = 'unit-test-jwt-secret';
  async function appFor() {
    const store = new MemoryDocumentStore();
    const repository = new FirestoreReadingOperationRepository(store);
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      async () => {
        throw new Error('reading operations must not call the AI provider');
      },
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingOperationRepository: repository,
        readingClock: new FixedClock(Date.parse('2026-10-10T00:00:00.000Z')),
        readingWaitPolicy: provisionalWaitPolicy({ coffee: 60_000, palm: 120_000, soulmate: 180_000 }),
      },
    );
    return { app, store };
  }
  const headers = (appCheck = 'good-token', withAuth = true) => ({
    ...(withAuth ? authHeader(signHs256(SECRET, { sub: 'user-a' })) : {}),
    ...appCheckHeader(appCheck),
  });
  const post = (app: Awaited<ReturnType<typeof appFor>>['app'], payload: Record<string, unknown>, h = headers()) =>
    app.inject({ method: 'POST', url: '/v1/reading-operations', headers: h, payload });
  const v3Body = { readingType: 'coffee', sourceRequestId: 'req-route-v3-01', coffeeInputContract: 'trusted_intention_v1', intention: INTENTION, coffeeCaptureContract: 'four_view_v3' };

  it('L/M: a body carrying coffeeCaptureContract is rejected with invalidRequest and creates nothing', async () => {
    const { app, store } = await appFor();
    const before = store.docs.size;
    for (const value of ['four_view_v3', null, 'anything']) {
      const res = await post(app, { ...v3Body, coffeeCaptureContract: value });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe('invalid_request');
    }
    expect(store.docs.size).toBe(before);
  });

  it('N/O/P: V2 marked Coffee, legacy Coffee, Palm and Soulmate creates are still accepted', async () => {
    const { app } = await appFor();
    const { coffeeCaptureContract: _drop, ...v2Body } = v3Body;
    expect((await post(app, { ...v2Body, sourceRequestId: 'req-route-v2-01' })).statusCode).toBe(200);
    expect((await post(app, { readingType: 'coffee', sourceRequestId: 'req-route-legacy-01' })).statusCode).toBe(200);
    expect((await post(app, { readingType: 'palm', sourceRequestId: 'req-route-palm-01' })).statusCode).toBe(200);
    expect((await post(app, { readingType: 'soulmate', sourceRequestId: 'req-route-soul-01' })).statusCode).toBe(200);
  });

  it('Q: auth and App Check still gate the route exactly as for a normal body', async () => {
    const { app } = await appFor();
    const normal = { readingType: 'coffee', sourceRequestId: 'req-route-auth-01' };
    for (const h of [headers('good-token', false), headers('bad-token')]) {
      const plain = await post(app, normal, h);
      const v3 = await post(app, v3Body, h);
      expect(plain.statusCode).not.toBe(200);
      expect(v3.statusCode).toBe(plain.statusCode);
    }
  });
});

describe('LIS1 staged slot model (R–Y)', () => {
  const rec = (slot?: string): ReadingStagedImageRecord => ({
    schemaVersion: 1,
    operationId: 'b'.repeat(32),
    ownerUserId: OWNER,
    readingType: 'coffee',
    objectPath: 'reading-staging/coffee/owner-a/x/input.jpg',
    contentType: 'image/jpeg',
    byteSize: 10,
    checksumSha256: 'c'.repeat(64),
    uploadState: 'complete',
    ...(slot ? { slot: slot as ReadingStagedImageRecord['slot'] } : {}),
    createdAtMs: 1,
    updatedAtMs: 1,
  });

  it('R/S: V2 slots are unchanged; V3 staged slots are namespaced, in canonical order', () => {
    expect(COFFEE_V2_SLOTS).toEqual(['cup_primary', 'cup_secondary', 'saucer']);
    expect(COFFEE_V3_STAGED_SLOTS).toEqual([...V3]);
  });

  it('T/U: V2 and V3 doc ids and object paths never collide', () => {
    const op = 'd'.repeat(32);
    expect(stagedDocId(op, 'saucer')).toBe(`${op}--saucer`);
    expect(stagedDocId(op, 'v3_saucer')).toBe(`${op}--v3_saucer`);
    const ids = [...COFFEE_V2_SLOTS, ...COFFEE_V3_STAGED_SLOTS].map((s) => stagedDocId(op, s));
    expect(new Set([...ids, stagedDocId(op)]).size).toBe(8);
    const paths = [...COFFEE_V2_SLOTS, ...COFFEE_V3_STAGED_SLOTS].map((slot) => stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op, ext: 'jpg', slot }));
    expect(new Set([...paths, stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op, ext: 'jpg' })]).size).toBe(8);
    expect(stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op, ext: 'jpg', slot: 'v3_saucer' })).toBe(`reading-staging/coffee/owner-a/${op}/v3_saucer.jpg`);
  });

  it('V/W/X/Y: the stored parser accepts V2, V3 and slot-absent records, rejects unknown slots', () => {
    for (const slot of [...COFFEE_V2_SLOTS, ...COFFEE_V3_STAGED_SLOTS]) {
      expect(parseStoredStagedImageRecord(toStoredStagedImageDocument(rec(slot)))?.slot, slot).toBe(slot);
    }
    expect(parseStoredStagedImageRecord(toStoredStagedImageDocument(rec()))?.slot).toBeUndefined();
    for (const bad of ['cup_handle_far', 'v3_cup_primary', 'V3_SAUCER', 'saucer2']) {
      expect(parseStoredStagedImageRecord({ ...toStoredStagedImageDocument(rec()), slot: bad }), bad).toBeNull();
    }
  });
});

describe('LIS1 staging ownership and duplicates', () => {
  it('null-contract Coffee: V2 slots and unslotted legacy pass; any V3 slot fails', async () => {
    const h = harness();
    const op = await v2Op(h);
    for (const [i, slot] of COFFEE_V2_SLOTS.entries()) expect(await errCode(stage(h, op.operationId, slot, fakeJpeg(10000 + i * 10)))).toBe('ok');
    for (const slot of V3) expect(await errCode(stage(h, op.operationId, slot, fakeJpeg(11000)))).toBe('invalid');
    const legacy = await v2Op(h);
    expect(await errCode(stage(h, legacy.operationId, undefined, fakeJpeg(10100)))).toBe('ok');
    // The V2 read side still sees only V2 records.
    expect((await h.stagedRepository.listSlots(op.operationId, OWNER)).map((r) => r.slot)).toEqual([...COFFEE_V2_SLOTS]);
    expect(await h.stagedRepository.listCoffeeV3Slots(op.operationId, OWNER)).toEqual([]);
  });

  it('four_view_v3 Coffee: the four V3 slots pass; V2 slots, no slot and unknown slots fail', async () => {
    const h = harness();
    const op = await v3Op(h);
    for (const slot of ['cup_primary', 'cup_secondary', 'saucer', undefined, 'cup_handle_far', 'v3_unknown']) {
      expect(await errCode(stage(h, op.operationId, slot, fakeJpeg(11100))), String(slot)).toBe('invalid');
    }
    await stageAllV3(h, op.operationId);
    expect((await h.stagedRepository.listCoffeeV3Slots(op.operationId, OWNER)).map((r) => r.slot)).toEqual([...V3]);
    expect(await h.stagedRepository.listSlots(op.operationId, OWNER)).toEqual([]);
    expect(await h.service.hasAnyCoffeeV2Slot({ ownerUserId: OWNER, operationId: op.operationId })).toBe(false);
  });

  it('Palm is unchanged: no slot of either contract is ever valid', async () => {
    const h = harness();
    const palm = await h.operations.create({ ownerUserId: OWNER, readingType: 'palm', sourceRequestId: source('palm') });
    for (const slot of ['cup_primary', 'v3_saucer']) {
      expect(await errCode(h.service.stage({ ownerUserId: OWNER, operationId: palm.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(10200).toString('base64'), handSide: 'left', slot }))).toBe('invalid');
    }
    expect(await errCode(h.service.stage({ ownerUserId: OWNER, operationId: palm.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(10200).toString('base64'), handSide: 'left' }))).toBe('ok');
  });

  it('V3 duplicates: the same bytes in two V3 slots fail; restaging one slot is idempotent; distinct images pass', async () => {
    const h = harness();
    const op = await v3Op(h);
    const x = fakeJpeg(13000);
    await stage(h, op.operationId, 'v3_cup_handle_far', x);
    await expect(stage(h, op.operationId, 'v3_cup_turn_a', x)).rejects.toMatchObject({ code: 'duplicate_staged_image', httpStatus: 409 });
    expect(await errCode(stage(h, op.operationId, 'v3_cup_handle_far', x))).toBe('ok');
    const other = await v3Op(h);
    expect(await errCode(stageAllV3(h, other.operationId))).toBe('ok');
  });
});

describe('LIS1 dark V3 retrieval and cleanup', () => {
  it('retrieves exactly four images, in V3 staging order, with checksum / MIME / bytes / owner checked', async () => {
    const h = harness();
    const op = await v3Op(h);
    await stageAllV3(h, op.operationId);
    const images = await h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: op.operationId });
    expect(images.map((i) => i.slot)).toEqual([...V3]);
    images.forEach((img, i) => {
      expect(img.mimeType).toBe('image/jpeg');
      expect(img.bytes.equals(fakeJpeg(12000 + i * 100))).toBe(true);
    });
  });

  it('missing, pending, corrupt, wrong owner, V2 and legacy operations all fail closed', async () => {
    const h = harness();
    const missing = await v3Op(h);
    for (const [i, slot] of V3.slice(0, 3).entries()) await stage(h, missing.operationId, slot, fakeJpeg(12000 + i * 100));
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: missing.operationId }))).toBe('invalid');

    const pending = await v3Op(h);
    await stageAllV3(h, pending.operationId);
    const rec = (await h.stagedRepository.getCoffeeV3Slot(pending.operationId, 'v3_cup_turn_b', OWNER))!;
    await h.stagedRepository.upsert({ ...rec, uploadState: 'pending' });
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: pending.operationId }))).toBe('invalid');

    const corrupt = await v3Op(h);
    await stageAllV3(h, corrupt.operationId);
    const sau = (await h.stagedRepository.getCoffeeV3Slot(corrupt.operationId, 'v3_saucer', OWNER))!;
    await h.objects.put(sau.objectPath, fakeJpeg(14999), 'image/jpeg');
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: corrupt.operationId }))).toBe('invalid');

    const owned = await v3Op(h);
    await stageAllV3(h, owned.operationId);
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: 'owner-b', operationId: owned.operationId }))).toBe('not_found');

    const v2 = await v2Op(h);
    for (const [i, slot] of COFFEE_V2_SLOTS.entries()) await stage(h, v2.operationId, slot, fakeJpeg(10000 + i * 10));
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: v2.operationId }))).toBe('not_found');
    const legacy = await v2Op(h);
    await stage(h, legacy.operationId, undefined, fakeJpeg(10100));
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: legacy.operationId }))).toBe('not_found');
  });

  it('V3 cleanup removes exactly the four V3 slots; V2 slots and the legacy record are never touched; idempotent', async () => {
    const h = harness();
    const op = await v3Op(h);
    await stageAllV3(h, op.operationId);
    // Plant V2-shaped and legacy-shaped records under the same operation id directly.
    const planted = (slot?: 'cup_primary' | 'cup_secondary' | 'saucer'): ReadingStagedImageRecord => ({
      schemaVersion: 1, operationId: op.operationId, ownerUserId: OWNER, readingType: 'coffee',
      objectPath: stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op.operationId, ext: 'jpg', slot }),
      contentType: 'image/jpeg', byteSize: 10, checksumSha256: 'e'.repeat(64), uploadState: 'complete',
      ...(slot ? { slot } : {}), createdAtMs: 1, updatedAtMs: 1,
    });
    for (const slot of [...COFFEE_V2_SLOTS, undefined]) {
      const r = planted(slot);
      await h.stagedRepository.upsert(r);
      await h.objects.put(r.objectPath, fakeJpeg(9000), 'image/jpeg');
    }
    await h.service.deleteCoffeeV3Slots({ ownerUserId: OWNER, operationId: op.operationId });
    await h.service.deleteCoffeeV3Slots({ ownerUserId: OWNER, operationId: op.operationId });
    expect(await h.stagedRepository.listCoffeeV3Slots(op.operationId, OWNER)).toEqual([]);
    expect((await h.stagedRepository.listSlots(op.operationId, OWNER)).map((r) => r.slot)).toEqual([...COFFEE_V2_SLOTS]);
    expect(await h.stagedRepository.get(op.operationId, OWNER)).not.toBeNull();
    expect(h.objects.objects.size).toBe(4);
  });

  it('wrong-owner V3 cleanup is a safe no-op; V2 cleanup never touches V3 slots', async () => {
    const h = harness();
    const op = await v3Op(h);
    await stageAllV3(h, op.operationId);
    await h.service.deleteCoffeeV3Slots({ ownerUserId: 'owner-b', operationId: op.operationId });
    await h.service.deleteCoffeeV2Slots({ ownerUserId: OWNER, operationId: op.operationId });
    expect((await h.stagedRepository.listCoffeeV3Slots(op.operationId, OWNER)).map((r) => r.slot)).toEqual([...V3]);
    expect(h.objects.objects.size).toBe(4);
  });
});

describe('LIS1 nothing live reaches V3', () => {
  const src = resolve(process.cwd(), 'src');
  const walk = (dir: string): string[] =>
    readdirSync(dir).flatMap((name) => {
      const path = join(dir, name);
      return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
    });
  const users = (re: RegExp, root = src) => walk(root).filter((p) => re.test(readFileSync(p, 'utf8'))).map((p) => p.slice(root.length + 1).replace(/\\/g, '/')).sort();

  it('the contract and the V3 staging APIs are referenced only by the model / service / repository / route-guard files', () => {
    expect(users(/four_view_v3|coffeeCaptureContract/)).toEqual([
      'reading/operation-model.ts',
      'reading/operation-service.ts',
      'reading/operation-staged-image-model.ts',
      'reading/operation-staged-image-service.ts',
      'routes/reading-operations.ts',
    ]);
    expect(users(/retrieveCoffeeV3ForProcessing|deleteCoffeeV3Slots|COFFEE_V3_STAGED_SLOTS|listCoffeeV3Slots/)).toEqual([
      'reading/operation-staged-image-model.ts',
      'reading/operation-staged-image-repository.ts',
      'reading/operation-staged-image-service.ts',
    ]);
  });

  it('worker, pipeline, service dispatch and gem acceleration have no V3 path', () => {
    for (const file of ['reading/reading-processor.ts', 'reading/reading-processor-execute.ts', 'ai/service.ts', 'ai/reading/pipeline.ts', 'routes/gem-acceleration.ts', 'reading/reading-task-scheduler.ts']) {
      const text = readFileSync(join(src, file), 'utf8');
      expect(text, file).not.toMatch(/four_view_v3|coffeeCaptureContract|COFFEE_V3_STAGED_SLOTS|CoffeeV3|coffeeV3|v3_saucer/);
    }
  });

  it('no client code references the new contract', () => {
    const lib = resolve(process.cwd(), '..', 'lib');
    const dart = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? dart(path) : path.endsWith('.dart') ? [path] : [];
      });
    expect(dart(lib).filter((p) => /four_view_v3|coffeeCaptureContract|v3_cup_|v3_saucer/.test(readFileSync(p, 'utf8')))).toEqual([]);
  });
});

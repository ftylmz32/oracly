/**
 * LIS1 — Coffee V3 THREE-photo staging contract (two genuine cup views + one
 * saucer) + immutable operation discriminator. The retired 'four_view_v3'
 * contract still parses (never mistaken for V2) but can never be created or
 * staged. DARK: the public create route refuses the field unless the server
 * flag is on. Zero provider calls.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import {
  COFFEE_CAPTURE_CONTRACTS,
  COFFEE_V3_CAPTURE_CONTRACT,
  isCoffeeCaptureContract,
  parseStoredRecord,
  toStoredDocument,
} from '../src/reading/operation-model.js';
import { FirestoreReadingOperationRepository, idempotencyKeyFor } from '../src/reading/operation-repository.js';
import { ReadingOperationError, ReadingOperationService } from '../src/reading/operation-service.js';
import {
  COFFEE_V2_SLOTS,
  COFFEE_V3_RETIRED_STAGED_SLOTS,
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
const V3 = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;
const RETIRED = ['v3_cup_handle_far', 'v3_cup_turn_a', 'v3_cup_turn_b', 'v3_saucer'] as const;

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
    coffeeCaptureContract: 'three_view_v3',
  });
}
/** A persisted pre-decision 'four_view_v3' operation (no longer creatable through the service). */
async function retiredOp(h: ReturnType<typeof harness>, owner = OWNER) {
  const op = await v3Op(h, owner);
  return h.operationRepository.mutate(op.operationId, owner, (r) => ({ ...r, coffeeCaptureContract: 'four_view_v3' }));
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

  it('B: three_view_v3 stores and parses; the retired four_view_v3 still parses as itself (never as V2 / legacy)', () => {
    for (const contract of ['three_view_v3', 'four_view_v3'] as const) {
      const rec = parseStoredRecord(base({ coffeeInputContract: 'trusted_intention_v1', coffeeIntention: INTENTION, coffeeCaptureContract: contract }))!;
      expect(rec.coffeeCaptureContract).toBe(contract);
      expect(toStoredDocument(rec).coffeeCaptureContract).toBe(contract);
      expect(parseStoredRecord(toStoredDocument(rec) as Record<string, unknown>)!.coffeeCaptureContract).toBe(contract);
      expect(isCoffeeCaptureContract(contract)).toBe(true);
    }
    expect(COFFEE_CAPTURE_CONTRACTS).toEqual(['three_view_v3', 'four_view_v3']);
    expect(COFFEE_V3_CAPTURE_CONTRACT).toBe('three_view_v3');
  });

  it('C/D/E: an unknown value, or any value on Palm / Soulmate, fails closed', () => {
    expect(parseStoredRecord(base({ coffeeCaptureContract: 'three_view_v2' }))).toBeNull();
    expect(parseStoredRecord(base({ coffeeCaptureContract: 4 }))).toBeNull();
    for (const contract of ['three_view_v3', 'four_view_v3']) {
      expect(parseStoredRecord(base({ readingType: 'palm', coffeeCaptureContract: contract }))).toBeNull();
      expect(parseStoredRecord(base({ readingType: 'soulmate', coffeeCaptureContract: contract }))).toBeNull();
    }
  });

  it('D/E/F (service): V3 requires Coffee + trusted_intention_v1 + a valid intention', async () => {
    const h = harness();
    for (const readingType of ['palm', 'soulmate'] as const) {
      expect(await errCode(h.operations.create({ ownerUserId: OWNER, readingType, sourceRequestId: source('x'), coffeeCaptureContract: 'three_view_v3' }))).toBe('invalid');
    }
    expect(await errCode(h.operations.create({ ownerUserId: OWNER, readingType: 'coffee', sourceRequestId: source('x'), coffeeCaptureContract: 'three_view_v3' }))).toBe('invalid');
    expect(await errCode(h.operations.create({ ownerUserId: OWNER, readingType: 'coffee', sourceRequestId: source('x'), coffeeInputContract: 'trusted_intention_v1', coffeeIntention: '   ', coffeeCaptureContract: 'three_view_v3' }))).toBe('invalid');
    const op = await v3Op(h);
    expect(op).toMatchObject({ readingType: 'coffee', coffeeInputContract: 'trusted_intention_v1', coffeeCaptureContract: 'three_view_v3' });
    expect((await h.operationRepository.getById(op.operationId))!.coffeeCaptureContract).toBe('three_view_v3');
  });

  it('the retired four_view_v3 can never be created again, even fully marked (nothing stored)', async () => {
    const h = harness();
    const before = h.store.docs.size;
    expect(await errCode(h.operations.create({ ownerUserId: OWNER, readingType: 'coffee', sourceRequestId: source('retired'), coffeeInputContract: 'trusted_intention_v1', coffeeIntention: INTENTION, coffeeCaptureContract: 'four_view_v3' }))).toBe('invalid');
    expect(h.store.docs.size).toBe(before);
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
    expect(idempotencyKeyFor({ ...k, coffeeCaptureContract: 'three_view_v3' } as typeof k)).toBe(idempotencyKeyFor(k));
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
    expect(failed.coffeeCaptureContract).toBe('three_view_v3');
    expect((await h.operationRepository.getById(op.operationId))!.coffeeCaptureContract).toBe('three_view_v3');
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
  const v3Body = { readingType: 'coffee', sourceRequestId: 'req-route-v3-01', coffeeInputContract: 'trusted_intention_v1', intention: INTENTION, coffeeCaptureContract: 'three_view_v3' };

  it('L/M: a body carrying coffeeCaptureContract is rejected with invalidRequest and creates nothing', async () => {
    const { app, store } = await appFor();
    const before = store.docs.size;
    for (const value of ['three_view_v3', 'four_view_v3', null, 'anything']) {
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

  it('R/S: V2 slots are unchanged; V3 staged slots are exactly two cup views + one saucer, namespaced, in canonical order', () => {
    expect(COFFEE_V2_SLOTS).toEqual(['cup_primary', 'cup_secondary', 'saucer']);
    expect(COFFEE_V3_STAGED_SLOTS).toEqual([...V3]);
    expect(COFFEE_V3_STAGED_SLOTS).toHaveLength(3);
    expect(COFFEE_V3_RETIRED_STAGED_SLOTS).toEqual([...RETIRED]);
    for (const slot of COFFEE_V3_STAGED_SLOTS) expect(COFFEE_V3_RETIRED_STAGED_SLOTS as readonly string[]).not.toContain(slot);
  });

  it('T/U: V2 and V3 doc ids and object paths never collide', () => {
    const op = 'd'.repeat(32);
    expect(stagedDocId(op, 'saucer')).toBe(`${op}--saucer`);
    expect(stagedDocId(op, 'v3_saucer_view')).toBe(`${op}--v3_saucer_view`);
    // V2, live V3 and retired four-view slots never share a doc id or object path.
    const all = [...COFFEE_V2_SLOTS, ...COFFEE_V3_STAGED_SLOTS, ...COFFEE_V3_RETIRED_STAGED_SLOTS];
    const ids = all.map((s) => stagedDocId(op, s));
    expect(new Set([...ids, stagedDocId(op)]).size).toBe(11);
    const paths = all.map((slot) => stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op, ext: 'jpg', slot }));
    expect(new Set([...paths, stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op, ext: 'jpg' })]).size).toBe(11);
    expect(stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op, ext: 'jpg', slot: 'v3_saucer_view' })).toBe(`reading-staging/coffee/owner-a/${op}/v3_saucer_view.jpg`);
  });

  it('V/W/X/Y: the stored parser accepts V2, V3 and slot-absent records, rejects unknown slots', () => {
    for (const slot of [...COFFEE_V2_SLOTS, ...COFFEE_V3_STAGED_SLOTS, ...COFFEE_V3_RETIRED_STAGED_SLOTS]) {
      expect(parseStoredStagedImageRecord(toStoredStagedImageDocument(rec(slot)))?.slot, slot).toBe(slot);
    }
    expect(parseStoredStagedImageRecord(toStoredStagedImageDocument(rec()))?.slot).toBeUndefined();
    for (const bad of ['cup_handle_far', 'cup_view_a', 'v3_cup_primary', 'V3_SAUCER', 'v3_cup_view_c', 'saucer2']) {
      expect(parseStoredStagedImageRecord({ ...toStoredStagedImageDocument(rec()), slot: bad }), bad).toBeNull();
    }
  });
});

describe('LIS1 staging ownership and duplicates', () => {
  it('null-contract Coffee: V2 slots and unslotted legacy pass; any V3 slot fails', async () => {
    const h = harness();
    const op = await v2Op(h);
    for (const [i, slot] of COFFEE_V2_SLOTS.entries()) expect(await errCode(stage(h, op.operationId, slot, fakeJpeg(10000 + i * 10)))).toBe('ok');
    for (const slot of [...V3, ...RETIRED]) expect(await errCode(stage(h, op.operationId, slot, fakeJpeg(11000)))).toBe('invalid');
    const legacy = await v2Op(h);
    expect(await errCode(stage(h, legacy.operationId, undefined, fakeJpeg(10100)))).toBe('ok');
    // The V2 read side still sees only V2 records.
    expect((await h.stagedRepository.listSlots(op.operationId, OWNER)).map((r) => r.slot)).toEqual([...COFFEE_V2_SLOTS]);
    expect(await h.stagedRepository.listCoffeeV3Slots(op.operationId, OWNER)).toEqual([]);
  });

  it('three_view_v3 Coffee: the three V3 slots pass; V2 slots, no slot, retired four-view slots and unknown slots fail', async () => {
    const h = harness();
    const op = await v3Op(h);
    for (const slot of ['cup_primary', 'cup_secondary', 'saucer', undefined, 'cup_view_a', 'v3_unknown', ...RETIRED]) {
      expect(await errCode(stage(h, op.operationId, slot, fakeJpeg(11100))), String(slot)).toBe('invalid');
    }
    await stageAllV3(h, op.operationId);
    expect((await h.stagedRepository.listCoffeeV3Slots(op.operationId, OWNER)).map((r) => r.slot)).toEqual([...V3]);
    expect(await h.stagedRepository.listSlots(op.operationId, OWNER)).toEqual([]);
    expect(await h.service.hasAnyCoffeeV2Slot({ ownerUserId: OWNER, operationId: op.operationId })).toBe(false);
  });

  it('a retired four_view_v3 operation accepts no upload at all (no fourth photo is ever requested)', async () => {
    const h = harness();
    const op = await retiredOp(h);
    for (const slot of [...RETIRED, ...V3, ...COFFEE_V2_SLOTS, undefined]) {
      expect(await errCode(stage(h, op.operationId, slot, fakeJpeg(11200))), String(slot)).toBe('invalid');
    }
    expect(h.objects.objects.size).toBe(0);
  });

  it('Palm is unchanged: no slot of either contract is ever valid', async () => {
    const h = harness();
    const palm = await h.operations.create({ ownerUserId: OWNER, readingType: 'palm', sourceRequestId: source('palm') });
    for (const slot of ['cup_primary', 'v3_saucer_view', 'v3_saucer']) {
      expect(await errCode(h.service.stage({ ownerUserId: OWNER, operationId: palm.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(10200).toString('base64'), handSide: 'left', slot }))).toBe('invalid');
    }
    expect(await errCode(h.service.stage({ ownerUserId: OWNER, operationId: palm.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(10200).toString('base64'), handSide: 'left' }))).toBe('ok');
  });

  it('V3 duplicates: the same bytes in two V3 slots fail; restaging one slot is idempotent; distinct images pass', async () => {
    const h = harness();
    const op = await v3Op(h);
    const x = fakeJpeg(13000);
    await stage(h, op.operationId, 'v3_cup_view_a', x);
    // The same photo can never stand in for the second cup view or the saucer.
    await expect(stage(h, op.operationId, 'v3_cup_view_b', x)).rejects.toMatchObject({ code: 'duplicate_staged_image', httpStatus: 409 });
    await expect(stage(h, op.operationId, 'v3_saucer_view', x)).rejects.toMatchObject({ code: 'duplicate_staged_image', httpStatus: 409 });
    expect(await errCode(stage(h, op.operationId, 'v3_cup_view_a', x))).toBe('ok');
    const other = await v3Op(h);
    expect(await errCode(stageAllV3(h, other.operationId))).toBe('ok');
  });
});

describe('LIS1 dark V3 retrieval and cleanup', () => {
  it('retrieves exactly three images (two cup + saucer), in V3 staging order, with checksum / MIME / bytes / owner checked', async () => {
    const h = harness();
    const op = await v3Op(h);
    await stageAllV3(h, op.operationId);
    const images = await h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: op.operationId });
    expect(images.map((i) => i.slot)).toEqual([...V3]);
    expect(images).toHaveLength(3);
    images.forEach((img, i) => {
      expect(img.mimeType).toBe('image/jpeg');
      expect(img.bytes.equals(fakeJpeg(12000 + i * 100))).toBe(true);
    });
  });

  it('missing, pending, corrupt, wrong owner, retired, V2 and legacy operations all fail closed', async () => {
    const h = harness();
    const missing = await v3Op(h);
    for (const [i, slot] of V3.slice(0, 2).entries()) await stage(h, missing.operationId, slot, fakeJpeg(12000 + i * 100));
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: missing.operationId }))).toBe('invalid');

    const pending = await v3Op(h);
    await stageAllV3(h, pending.operationId);
    const rec = (await h.stagedRepository.getCoffeeV3Slot(pending.operationId, 'v3_cup_view_b', OWNER))!;
    await h.stagedRepository.upsert({ ...rec, uploadState: 'pending' });
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: pending.operationId }))).toBe('invalid');

    const corrupt = await v3Op(h);
    await stageAllV3(h, corrupt.operationId);
    const sau = (await h.stagedRepository.getCoffeeV3Slot(corrupt.operationId, 'v3_saucer_view', OWNER))!;
    await h.objects.put(sau.objectPath, fakeJpeg(14999), 'image/jpeg');
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: corrupt.operationId }))).toBe('invalid');

    const owned = await v3Op(h);
    await stageAllV3(h, owned.operationId);
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: 'owner-b', operationId: owned.operationId }))).toBe('not_found');

    const hr = harness();
    const retired = await retiredOp(hr);
    expect(await errCode(hr.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: retired.operationId }))).toBe('not_found');

    const v2 = await v2Op(h);
    for (const [i, slot] of COFFEE_V2_SLOTS.entries()) await stage(h, v2.operationId, slot, fakeJpeg(10000 + i * 10));
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: v2.operationId }))).toBe('not_found');
    const legacy = await v2Op(h);
    await stage(h, legacy.operationId, undefined, fakeJpeg(10100));
    expect(await errCode(h.service.retrieveCoffeeV3ForProcessing({ ownerUserId: OWNER, operationId: legacy.operationId }))).toBe('not_found');
  });

  it('V3 cleanup removes exactly the three V3 slots; V2 slots and the legacy record are never touched; idempotent', async () => {
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

  it('V3 cleanup also removes the leftover slots of a retired four-view operation (privacy), and nothing else', async () => {
    const h = harness();
    const op = await retiredOp(h);
    for (const [i, slot] of RETIRED.entries()) {
      const r: ReadingStagedImageRecord = {
        schemaVersion: 1, operationId: op.operationId, ownerUserId: OWNER, readingType: 'coffee',
        objectPath: stagedObjectPath({ readingType: 'coffee', ownerUserId: OWNER, operationId: op.operationId, ext: 'jpg', slot }),
        contentType: 'image/jpeg', byteSize: 10, checksumSha256: String(i).repeat(64), uploadState: 'complete',
        slot, createdAtMs: 1, updatedAtMs: 1,
      };
      await h.stagedRepository.upsert(r);
      await h.objects.put(r.objectPath, fakeJpeg(9100 + i), 'image/jpeg');
    }
    const other = await v3Op(h);
    await stageAllV3(h, other.operationId);
    expect(h.objects.objects.size).toBe(7);
    await h.service.deleteCoffeeV3Slots({ ownerUserId: OWNER, operationId: op.operationId });
    expect(h.objects.objects.size).toBe(3);
    for (const slot of RETIRED) expect(await h.stagedRepository.getCoffeeV3Slot(op.operationId, slot, OWNER)).toBeNull();
    expect((await h.stagedRepository.listCoffeeV3Slots(other.operationId, OWNER)).map((r) => r.slot)).toEqual([...V3]);
  });

  it('wrong-owner V3 cleanup is a safe no-op; V2 cleanup never touches V3 slots', async () => {
    const h = harness();
    const op = await v3Op(h);
    await stageAllV3(h, op.operationId);
    await h.service.deleteCoffeeV3Slots({ ownerUserId: 'owner-b', operationId: op.operationId });
    await h.service.deleteCoffeeV2Slots({ ownerUserId: OWNER, operationId: op.operationId });
    expect((await h.stagedRepository.listCoffeeV3Slots(op.operationId, OWNER)).map((r) => r.slot)).toEqual([...V3]);
    expect(h.objects.objects.size).toBe(3);
  });
});

// Updated by LIS2: the worker, the internal AI entry and gem acceleration now
// own V3 by contract; the V2 pipeline, the public coffee handler and the
// scheduler still never see it.
describe('LIS1/LIS2 V3 ownership boundaries', () => {
  const src = resolve(process.cwd(), 'src');
  const walk = (dir: string): string[] =>
    readdirSync(dir).flatMap((name) => {
      const path = join(dir, name);
      return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
    });
  const users = (re: RegExp, root = src) => walk(root).filter((p) => re.test(readFileSync(p, 'utf8'))).map((p) => p.slice(root.length + 1).replace(/\\/g, '/')).sort();

  it('the contract is referenced only by the model / service / staging / worker / gem / create-route files', () => {
    expect(users(/four_view_v3|three_view_v3|coffeeCaptureContract/)).toEqual([
      'ai/reading/coffee-v3-live-pipeline.ts',
      'ai/service.ts',
      'reading/operation-model.ts',
      'reading/operation-service.ts',
      'reading/operation-staged-image-model.ts',
      'reading/operation-staged-image-service.ts',
      'reading/reading-processor-execute.ts',
      'reading/reading-processor.ts',
      'routes/gem-acceleration.ts',
      'routes/reading-operations.ts',
    ]);
    expect(users(/coffee-v3-live-pipeline/)).toEqual(['ai/service.ts', 'reading/reading-processor-execute.ts']);
  });

  it('the V2 pipeline, the public coffee handler and the scheduler have no V3 path', () => {
    for (const file of ['ai/reading/pipeline.ts', 'reading/reading-task-scheduler.ts']) {
      expect(readFileSync(join(src, file), 'utf8'), file).not.toMatch(/four_view_v3|three_view_v3|coffeeCaptureContract|COFFEE_V3_STAGED_SLOTS|CoffeeV3|coffeeV3|v3_saucer/);
    }
    const service = readFileSync(join(src, 'ai/service.ts'), 'utf8');
    const publicCoffee = service.slice(service.indexOf('private async coffee('), service.indexOf('LIS2 — INTERNAL Coffee V3 entry'));
    expect(publicCoffee.length).toBeGreaterThan(100);
    expect(publicCoffee).not.toMatch(/four_view_v3|three_view_v3|coffeeCaptureContract|coffeeV3|runCoffeeV3Reading|v3_/);
  });

});

/**
 * Slice 4 / 4D — current-phase DARK ROLLOUT guarantees. Replaces the LIS1
 * backend-only assertion "no client code references the new contract",
 * which the approved Slice 4 Flutter client intentionally superseded. The
 * client contract is now present ON PURPOSE; what must hold is that it is
 * aligned with the backend and stays dark by default on both sides. (No
 * file counts: those would only produce brittle, meaningless failures.)
 * Behavioral proof of the client routing lives in the Flutter suite pinned
 * below; server-side behavior is proven in this file (L–Q) and in
 * coffee-v3-live-pipeline.test.ts (create gate BD–BL, worker AS–BC).
 */
describe('Slice 4 V3 dark rollout contract (client + server)', () => {
  const repo = resolve(process.cwd(), '..');
  const read = (rel: string) => readFileSync(join(repo, rel), 'utf8');
  const V3_DIR = 'lib/features/coffee/coffee_v3';
  const indexOf = (text: string, needle: string) => {
    const at = text.indexOf(needle);
    expect(at, `missing: ${needle}`).toBeGreaterThanOrEqual(0);
    return at;
  };

  it('1/2: the client V3 contract is intentionally present and matches the backend contract + slots in order', () => {
    const contract = read(`${V3_DIR}/models/coffee_v3_capture_contract.dart`);
    const clientContract = /coffeeV3CaptureContract = '([^']+)'/.exec(contract)?.[1];
    expect(clientContract).toBe(COFFEE_V3_CAPTURE_CONTRACT);
    expect(isCoffeeCaptureContract(clientContract)).toBe(true);

    const slots = read(`${V3_DIR}/models/coffee_v3_photo_slot.dart`);
    const wireSwitch = slots.slice(indexOf(slots, 'String get wireValue'), indexOf(slots, 'coffeeV3PhotoSlotFromWire'));
    const wire = new Map([...wireSwitch.matchAll(/CoffeeV3PhotoSlot\.(\w+) => '([^']+)'/g)].map((m) => [m[1], m[2]]));
    const orderBlock = slots.slice(indexOf(slots, 'coffeeV3CanonicalSlotOrder = ['));
    const order = [...orderBlock.slice(0, orderBlock.indexOf('];')).matchAll(/CoffeeV3PhotoSlot\.(\w+)/g)].map((m) => m[1]);
    expect(order.map((name) => wire.get(name))).toEqual([...COFFEE_V3_STAGED_SLOTS]);
    expect(order).toHaveLength(3);
    // The client never knows a retired four-view slot.
    for (const retired of COFFEE_V3_RETIRED_STAGED_SLOTS) expect(slots).not.toContain(`'${retired}'`);
    // V2 slot vocabulary is never reused by the client V3 slots.
    for (const v2 of COFFEE_V2_SLOTS) expect([...wire.values()]).not.toContain(v2);
  });

  it('1: only the V3 submission controller sends the capture contract; Coffee V2 never does', () => {
    expect(read(`${V3_DIR}/services/coffee_v3_submission_controller.dart`)).toMatch(
      /coffeeCaptureContract: coffeeV3CaptureContract/,
    );
    const v2 = read('lib/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart');
    expect(v2).not.toMatch(/coffeeCaptureContract|four_view_v3|three_view_v3|v3_cup_|v3_saucer/);
    // The shared codec only forwards it for Coffee and omits it when null.
    expect(read('lib/features/reading_operation/services/reading_operation_codec.dart')).toMatch(
      /readingType == ReadingType\.coffee && coffeeCaptureContract != null/,
    );
  });

  it('3: the client rollout flag coffee_v3_three_view defaults to false (and is a real catalog flag)', () => {
    const flags = read('lib/core/feature_flags/product_feature_flags.dart');
    const def = /coffeeV3ThreeView = FeatureFlagDefinition\(([\s\S]*?)\);/.exec(flags)?.[1] ?? '';
    expect(def).toMatch(/key: 'coffee_v3_three_view'/);
    // The retired four-view key can never switch the new flow on.
    expect(flags).not.toMatch(/coffee_v3_four_view/);
    expect(def).toMatch(/defaultValue: false/);
    expect(def).not.toMatch(/defaultValue: true/);
    const catalog = flags.slice(indexOf(flags, 'static const catalog'));
    expect(catalog.slice(0, catalog.indexOf('];'))).toMatch(/coffeeV3ThreeView/);
    expect(read('lib/core/feature_flags/feature_flag_rollback.dart')).toMatch(
      /FeatureFlagSurface\.coffeeV3Capture => ProductFeatureFlags\.coffeeV3ThreeView/,
    );
  });

  it('4: NEW V3 creation requires BOTH the rollout gate AND a Turkish UI', () => {
    const gate = read(`${V3_DIR}/services/coffee_v3_creation_gate.dart`);
    expect(gate).toMatch(/requiredLanguage = 'tr'/);
    expect(gate).toMatch(/FeatureFlagSurface\.coffeeV3Capture/);
    expect(gate).toMatch(/creationAllowed => rolloutEnabled && languageSupported/);
  });

  it('5/6/7: entry routing keeps recovery ownership first and fresh Coffee on V2 by default', () => {
    const entry = read('lib/features/coffee/coffee_v2/presentation/coffee_v2_entry_gate.dart');
    const activeV3 = indexOf(entry, 'v3State == CoffeeV3StoredState.active');
    const v2Recovery = indexOf(entry, 'coffeeHasRecoverableV2SessionProvider');
    const legacy = indexOf(entry, 'coffeeHasLegacyPendingOperationProvider');
    const v3Draft = indexOf(entry, 'v3State == CoffeeV3StoredState.draft');
    const freshV3 = indexOf(entry, 'coffeeV3CreationAllowedProvider');
    const v2Default = entry.lastIndexOf('return const CoffeeV2FlowScreen();');
    // 7: an ACTIVE V3 operation is recovered before (and without) any
    //    creation gate; 6: V2 / legacy recovery precede new-flow choice;
    //    5: fresh V3 needs creation allowed, otherwise the V2 default.
    expect(activeV3).toBeLessThan(v2Recovery);
    expect(v2Recovery).toBeLessThan(legacy);
    expect(legacy).toBeLessThan(v3Draft);
    expect(v3Draft).toBeLessThan(freshV3);
    expect(freshV3).toBeLessThan(v2Default);
    expect(entry.slice(activeV3, v2Recovery)).not.toMatch(/CreationAllowed/);
    expect(entry.slice(freshV3, v2Default)).toMatch(/!ref\.watch\(coffeeHasV2DraftPhotosProvider\)/);

    // The behavioral proof (real flag runtime + language) stays in the
    // Flutter suite; pin that it exists and covers these scenarios.
    const flutter = read('test/features/coffee/coffee_v3/coffee_v3_entry_gate_test.dart');
    for (const scenario of [
      'B flag OFF (default) fresh Coffee → existing V2 flow',
      'C flag ON + tr fresh Coffee → V3 flow',
      'D flag ON + en/ru fresh Coffee → V2 flow',
      'E active V3 + flag OFF (or non-tr) → V3 recovery',
      'I V2 recoverable session wins over starting a NEW V3 session',
      'J legacy pending stays legacy (flag ON)',
    ]) {
      expect(flutter, scenario).toContain(scenario);
    }
    expect(read('test/features/coffee/coffee_v3/coffee_v3_flow_controller_test.dart')).toContain(
      'E flag-off ACTIVE V3 keeps recovering to its m2 result',
    );
  });

  it('8/9: server-side V3 creation is OFF by default and an unexpected V3 create fails closed', () => {
    for (const env of ['development', 'staging', 'production']) {
      expect(testConfig({ APP_ENV: env }).coffeeV3CreationEnabled).toBe(false);
    }
    expect(testConfig({ ORACLY_COFFEE_V3_ENABLED: 'maybe' }).coffeeV3CreationEnabled).toBe(false);
    // The L–Q route tests above run with exactly this default config, so
    // their 400 / nothing-created result IS the flag-OFF fail-closed path.
    expect(testConfig({ AI_JWT_SECRET: 'unit-test-jwt-secret', AI_APP_CHECK_REQUIRED: 'true' }).coffeeV3CreationEnabled).toBe(false);
  });

  it('10: V3 worker dispatch depends on the immutable contract, never on slot presence', () => {
    const exec = readFileSync(join(process.cwd(), 'src/reading/reading-processor-execute.ts'), 'utf8');
    const retired = indexOf(exec, "if (feature === 'coffee' && operation.coffeeCaptureContract === 'four_view_v3') {");
    const v3Decl = indexOf(exec, "const isCoffeeV3 = feature === 'coffee' && operation.coffeeCaptureContract === 'three_view_v3';");
    const v2Probe = indexOf(exec, 'hasAnyCoffeeV2Slot');
    // The retired contract settles before any V3 or V2 decision; it can never fall through to V2.
    expect(retired).toBeLessThan(v3Decl);
    expect(exec.slice(retired, v3Decl)).toMatch(/return 'failed';/);
    expect(v3Decl).toBeLessThan(v2Probe);
    expect(exec.slice(v3Decl, v2Probe)).toMatch(/!isCoffeeV3 &&/);
    // No V3 slot-presence probe exists anywhere in the worker.
    expect(exec).not.toMatch(/hasAnyCoffeeV3Slot|listCoffeeV3Slots/);
  });
});

/**
 * Commerce on: a Coffee operation made before the rollout, owned and claimed
 * (`processing`), may be read through `/v1/ai/complete` coffee_analysis once.
 * Its first request key (phase suffix aside) is pinned server-side and each
 * phase is admitted once: the same key replays the delivered reading, a new
 * key or a repeated phase is refused before the provider. Commerce off: no
 * pin, no change.
 *
 * The provider is a counting fake (scripted observer + writer); no real AI.
 */
import { beforeEach, describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import type { OpenAiFetch } from '../src/types.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import { FirestoreResponseReplayRepository } from '../src/middleware/response-replay-repository.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  coffeeBody,
  coffeeObserverJson,
  coffeeMeaningWriterJson,
  fakeJpeg,
  openaiReadingSequence,
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

const SECRET = 'unit-test-jwt-secret';
const NOW = Date.parse('2026-10-27T10:00:00.000Z');
const WAIT = { coffee: 2 * 60 * 60 * 1000, palm: 4 * 60 * 60 * 1000, soulmate: 1000 };
const DENIED = 'reading_entitlement_required';
const PIN = 'readingLegacyDirectAi';
const DAY = 24 * 60 * 60 * 1000;
/**
 * Past the free-slot attempt window (70 s). Calls made "later" also go to a
 * fresh app instance: the duplicate-request guard and identity rate limit
 * keep wall-clock windows in memory, which a later real request is outside of.
 */
const PAST_ATTEMPT = 2 * 60 * 1000;

beforeEach(() => readingStageStore.clear());

/** provider: 'reads' answers with a scripted reading; 'fails' always errors. */
function backend(provider: 'reads' | 'fails' = 'reads') {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(NOW);
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(repository, clock, provisionalWaitPolicy(WAIT));
  const entitlements = new ReadingEntitlementLedger(store);
  const gems = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, gems, entitlements);
  const stagedImages = new ReadingStagedImageService(
    new FirestoreReadingStagedImageRepository(store),
    new MemoryStagedObjectStore(),
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
  );
  const replay = new FirestoreResponseReplayRepository(new MemoryDocumentStore());
  const calls = { provider: 0 };
  // Scripted like ai.test.ts: the first call observes, every later call writes.
  const script = openaiReadingSequence(coffeeObserverJson, coffeeMeaningWriterJson);
  const fetchImpl: OpenAiFetch = async (...args) => {
    calls.provider += 1;
    if (provider === 'fails') throw new Error('test provider: no real AI');
    return script(...args);
  };

  async function app(commerce: boolean, withPinStore = true) {
    return testApp(testConfig({
      AI_JWT_SECRET: SECRET,
      AI_APP_CHECK_REQUIRED: 'true',
      AI_DAILY_SPEND_CAP_USD: '5',
      OPENAI_API_KEY: 'sk-test-not-real',
      OPENAI_VISION: 'true',
      ORACLY_COFFEE_V3_ENABLED: 'true',
      READING_STAGING_BUCKET: 'test-bucket',
      ...(commerce ? { ORACLY_READING_COMMERCE_ENABLED: 'true' } : {}),
    }), fetchImpl, {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: repository,
      readingClock: clock,
      readingWaitPolicy: provisionalWaitPolicy(WAIT),
      gemStore: store,
      gemLedger: gems,
      readingFlow: flow,
      ritualQuotaStore: withPinStore ? store : undefined,
      readingStagedImages: stagedImages,
      responseReplayRepository: replay,
    });
  }

  const headers = (sub = 'user-a', extra: Record<string, string> = {}) => ({
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
    ...extra,
  });

  const count = (prefix: string) =>
    [...store.docs.keys()].filter((key) => key.startsWith(`${prefix}/`)).length;

  /** A legacy Coffee operation created before the rollout, staged, past its wait and (optionally) claimed. */
  async function legacyCoffee(sub = 'user-a', source = 'old-coffee-0001', claim = true) {
    const before = await app(false);
    const made = await before.inject({
      method: 'POST', url: '/v1/reading-operations', headers: headers(sub),
      payload: { readingType: 'coffee', sourceRequestId: source },
    });
    await before.close();
    const operationId = made.json().data.operationId as string;
    await stagedImages.stage({
      ownerUserId: identityKeyFromSubject(sub), operationId, mimeType: 'image/jpeg',
      imageBase64: fakeJpeg(12_000).toString('base64'),
    });
    if (claim) {
      clock.ms = Math.max(clock.ms, NOW + WAIT.coffee + 1);
      expect((await flow.claim(identityKeyFromSubject(sub), operationId)).execute).toBe(true);
    }
    return operationId;
  }

  return { store, clock, entitlements, gems, flow, calls, app, headers, count, legacyCoffee };
}

type App = Awaited<ReturnType<ReturnType<typeof backend>['app']>>;

function read(app: App, headers: Record<string, string>, operationId: string, extra: Record<string, unknown> = {}) {
  return app.inject({
    method: 'POST', url: '/v1/ai/complete', headers,
    payload: { operation: 'coffee_analysis', payload: { mimeType: 'image/jpeg', operationId, ...extra } },
  });
}

describe('commerce on: one legacy Coffee operation, one reading', () => {
  it('the first key reads once; the same key replays the delivered reading with no second provider call',
    async () => {
      const b = backend();
      const operationId = await b.legacyCoffee();
      const app = await b.app(true);
      const key = (k: string) => b.headers('user-a', { 'idempotency-key': k });
      const first = await read(app, key('legacy-coffee-key1'), operationId);
      expect(first.json().success).toBe(true);
      const afterFirst = b.calls.provider;
      expect(afterFirst).toBeGreaterThan(0);
      const again = await read(app, key('legacy-coffee-key1'), operationId);
      expect(again.statusCode).toBe(first.statusCode);
      expect(again.json()).toEqual(first.json());
      expect(b.calls.provider).toBe(afterFirst);
      await app.close();
    });

  it('a different key is refused: the same day and any later day, with no provider, gem or credit use',
    async () => {
      const b = backend();
      const owner = identityKeyFromSubject('user-a');
      await b.gems.credit({ ownerUserId: owner, amount: 25, idempotencyKey: 'seed-gems-01' });
      const operationId = await b.legacyCoffee();
      const app = await b.app(true);
      expect((await read(app, b.headers('user-a', { 'idempotency-key': 'legacy-coffee-key1' }), operationId)).json().success).toBe(true);
      const afterFirst = b.calls.provider;
      // Same day: refused (the old free-slot check answers first, or the gate).
      const sameDay = await read(app, b.headers('user-a', { 'idempotency-key': 'legacy-coffee-key2' }), operationId);
      expect(sameDay.json().success).toBe(false);
      // Later days: the free slot is open again; only the pin stops a second reading.
      for (const [i, k] of ['legacy-coffee-key3', 'legacy-coffee-key1x'].entries()) {
        b.clock.ms += DAY * (i + 1);
        const later = await b.app(true);
        const res = await read(later, b.headers('user-a', { 'idempotency-key': k }), operationId);
        await later.close();
        expect(res.statusCode).toBe(403);
        expect(res.json().error.code).toBe(DENIED);
      }
      // A new key under a phase the first key never used is still another reading.
      b.clock.ms += DAY;
      const otherPhase = await b.app(true);
      const observe = await read(otherPhase, b.headers('user-a', { 'idempotency-key': 'legacy-coffee-key4:observe' }), operationId, { readingPhase: 'observe' });
      await otherPhase.close();
      expect(observe.json().error.code).toBe(DENIED);
      expect(b.calls.provider).toBe(afterFirst);
      expect(await b.gems.balanceOf(owner)).toBe(25);
      expect((await b.entitlements.balance(owner)).coffee).toBe(0);
      await app.close();
    });

  it('the same key after a failed provider attempt is not read again (the old client fails the operation)',
    async () => {
      const b = backend('fails');
      const operationId = await b.legacyCoffee();
      const app = await b.app(true);
      const first = await read(app, b.headers('user-a', { 'idempotency-key': 'legacy-coffee-key1' }), operationId);
      expect(first.json().success).toBe(false);
      const afterFirst = b.calls.provider;
      expect(afterFirst).toBeGreaterThan(0);
      b.clock.ms += PAST_ATTEMPT;
      const later = await b.app(true);
      const again = await read(later, b.headers('user-a', { 'idempotency-key': 'legacy-coffee-key1' }), operationId);
      await later.close();
      expect(again.json().error.code).toBe(DENIED);
      expect(b.calls.provider).toBe(afterFirst);
      await app.close();
    });

  it('legacy two-phase reading: observe then write under one key are each admitted once', async () => {
    const b = backend('fails');
    const operationId = await b.legacyCoffee();
    const h = (k: string) => b.headers('user-a', { 'idempotency-key': k });
    const later = async (key: string, extra: Record<string, unknown>) => {
      b.clock.ms += PAST_ATTEMPT;
      const app = await b.app(true);
      const res = await read(app, h(key), operationId, extra);
      await app.close();
      return res.json().error?.code;
    };
    const write = { readingPhase: 'write', observationToken: 'x'.repeat(40) };
    expect(await later('two-phase-key1:observe', { readingPhase: 'observe' })).not.toBe(DENIED);
    expect(await later('two-phase-key1:write', write)).not.toBe(DENIED);
    const callsAfter = b.calls.provider;
    expect(await later('two-phase-key1:observe', { readingPhase: 'observe' })).toBe(DENIED);
    expect(await later('two-phase-key1:write', write)).toBe(DENIED);
    expect(await later('two-phase-key2:write', write)).toBe(DENIED);
    expect(b.calls.provider).toBe(callsAfter);
  });

  it('8 parallel requests with different keys produce at most one reading', async () => {
    const b = backend();
    const operationId = await b.legacyCoffee();
    const app = await b.app(true);
    const results = await Promise.all(Array.from({ length: 8 }, (_, i) =>
      read(app, b.headers('user-a', { 'idempotency-key': `race-coffee-key${i}` }), operationId)));
    expect(results.filter((r) => r.json().success === true).length).toBeLessThanOrEqual(1);
    const afterRace = b.calls.provider;
    expect(afterRace).toBeLessThanOrEqual(2); // one observer + one writer
    // A later day, 8 more parallel new keys: no second reading at all.
    await app.close();
    b.clock.ms += DAY;
    const nextDay = await b.app(true);
    const later = await Promise.all(Array.from({ length: 8 }, (_, i) =>
      read(nextDay, b.headers('user-a', { 'idempotency-key': `race-coffee-day2-${i}` }), operationId)));
    for (const res of later) expect(res.json().error?.code).toBe(DENIED);
    expect(b.calls.provider).toBe(afterRace);
    await nextDay.close();
  });

  it('8 parallel requests with the same key produce one reading', async () => {
    const b = backend();
    const operationId = await b.legacyCoffee();
    const app = await b.app(true);
    const results = await Promise.all(Array.from({ length: 8 }, () =>
      read(app, b.headers('user-a', { 'idempotency-key': 'same-coffee-key1' }), operationId)));
    expect(results.filter((r) => r.json().success === true).length).toBeGreaterThanOrEqual(1);
    expect(b.calls.provider).toBeLessThanOrEqual(2);
    await app.close();
  });
});

describe('commerce on: still refused before any pin', () => {
  it('another account, a waiting operation, forged payment fields, or no pin store', async () => {
    const b = backend();
    const waiting = await b.legacyCoffee('user-a', 'old-coffee-wait1', false);
    const claimed = await b.legacyCoffee('user-a', 'old-coffee-0002');
    const app = await b.app(true);
    expect((await read(app, b.headers('user-b', { 'idempotency-key': 'foreign-coffee-1' }), claimed)).json().error.code).toBe(DENIED);
    expect((await read(app, b.headers('user-a', { 'idempotency-key': 'waiting-coffee-1' }), waiting)).json().error.code).toBe(DENIED);
    const forged = coffeeBody();
    Object.assign(forged.payload as Record<string, unknown>, { paid: true, entitlement: 'coffee', purchaseToken: 'valid-1' });
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: b.headers('user-a', { 'idempotency-key': 'forged-coffee-01' }), payload: forged,
    });
    expect(res.json().error.code).toBe(DENIED);
    expect(b.count(PIN)).toBe(0);
    await app.close();
    const noStore = await b.app(true, false);
    expect((await read(noStore, b.headers('user-a', { 'idempotency-key': 'no-store-coffee1' }), claimed)).json().error.code).toBe(DENIED);
    await noStore.close();
    expect(b.calls.provider).toBe(0);
  });

  it('a request without a key is never served', async () => {
    const b = backend();
    const operationId = await b.legacyCoffee();
    const app = await b.app(true);
    const res = await read(app, b.headers('user-a'), operationId);
    expect(res.json().success).toBe(false);
    expect(b.calls.provider).toBe(0);
    expect(b.count(PIN)).toBe(0);
    await app.close();
  });

  it('the pin is owner-scoped, server-only data, and the operation stays recoverable', async () => {
    const b = backend();
    const owner = identityKeyFromSubject('user-a');
    const operationId = await b.legacyCoffee();
    const app = await b.app(true);
    await read(app, b.headers('user-a', { 'idempotency-key': 'legacy-coffee-key1' }), operationId);
    const pin = b.store.docs.get(`${PIN}/${operationId}`) as Record<string, unknown>;
    expect(pin).toMatchObject({ ownerUserId: owner, readingType: 'coffee', requestKey: 'legacy-coffee-key1' });
    expect(JSON.stringify(pin)).not.toMatch(/image|photo|intention|overall/i);
    const status = await app.inject({ method: 'GET', url: `/v1/reading-operations/${operationId}`, headers: b.headers() });
    expect(status.statusCode).toBe(200);
    expect((await b.flow.failFinal({ ownerUserId: owner, operationId, failureCode: 'unavailable' })).status).toBe('failed');
    await app.close();
  });
});

describe('commerce off: unchanged', () => {
  it('a claimed operation is read under any key and nothing is pinned', async () => {
    const b = backend();
    const operationId = await b.legacyCoffee();
    const app = await b.app(false);
    expect((await read(app, b.headers('user-a', { 'idempotency-key': 'off-coffee-key1' }), operationId)).json().success).toBe(true);
    const afterFirst = b.calls.provider;
    // As before: only the old free-slot check limits a new key (the next day it reads again).
    await app.close();
    b.clock.ms += DAY;
    const later = await b.app(false);
    const nextDay = await read(later, b.headers('user-a', { 'idempotency-key': 'off-coffee-key2' }), operationId);
    expect(nextDay.json().error?.code).not.toBe(DENIED);
    expect(b.calls.provider).toBeGreaterThan(afterFirst);
    expect(b.count(PIN)).toBe(0);
    await later.close();
  });
});

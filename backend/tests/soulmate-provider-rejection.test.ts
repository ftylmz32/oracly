/**
 * SM-RL1 — explicit provider rejection recovery. Focused matrix for the
 * NEW definitive-rejection retry path (rate_limited/moderation/invalid_
 * request) layered onto the existing Soulmate durable worker, proving:
 * (a) a definitive rejection no longer strands the checkpoint as
 * ambiguous `in_flight`; (b) a bounded, backoff-respecting retry is
 * permitted only for the retryable class; (c) truly ambiguous outcomes
 * (timeout/network/generic) are completely untouched by this change.
 *
 * SM-RL2 — timing values updated for the new attempt-aware fallback
 * floor (30s after attempt #1, 60s after attempt #2 — see
 * soulmate-processor-execute.ts's computeRateLimitBackoffMs), which
 * replaced the flat 2s default SM-PR1 found let 3 real provider attempts
 * land inside a 13.3s span in production.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import type { ServerClock } from '../src/reading/clock.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor, type ReadingCompletionNotifier } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy, SOULMATE_NO_COMMERCIAL_WAIT_MS } from '../src/reading/wait-policy.js';
import { testConfig } from './helpers.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import { FirestoreReadingOperationInputRepository } from '../src/reading/operation-input-repository.js';
import { ReadingOperationInputService } from '../src/reading/operation-input-service.js';
import { GcsSoulmatePortraitStore } from '../src/reading/soulmate-portrait-store.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import { ErrorCode, ProxyError } from '../src/errors.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date { return new Date(this.ms); }
}

class CounterNotifier implements ReadingCompletionNotifier {
  calls = 0;
  constructor(private readonly results: ReadingResultRepository) {}
  async notifyCompleted(input: { operationId: string }): Promise<void> {
    expect(await this.results.get(input.operationId)).not.toBeNull();
    this.calls++;
  }
}

function fakePng(label: string): Buffer {
  const bytes = Buffer.alloc(64);
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]).copy(bytes);
  Buffer.from(label).copy(bytes, 8);
  return bytes;
}

type PortraitBehavior = 'success' | { throw: unknown };

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-14T10:00:00Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ soulmate: SOULMATE_NO_COMMERCIAL_WAIT_MS }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const stagedImages = new ReadingStagedImageService(
    stagedRepository,
    new MemoryStagedObjectStore(),
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
  );
  const results = new ReadingResultRepository(store);
  const notifier = new CounterNotifier(results);
  const providerStages = new FirestoreProviderStageRepository(store, clock);
  const inputRepository = new FirestoreReadingOperationInputRepository(store);
  const soulmateInputs = new ReadingOperationInputService(inputRepository, operations, clock);
  const soulmatePortraits = new GcsSoulmatePortraitStore(new MemoryStagedObjectStore(), store);
  const entitlement = new InMemorySoulmateEntitlementGuard();

  let portraitCalls = 0;
  let interpretationCalls = 0;
  const portraitQueue: PortraitBehavior[] = [];
  const ai = {
    async handle(request: { operation: string }) {
      if (request.operation === 'soulmate_draw') {
        portraitCalls++;
        const behavior = portraitQueue.shift() ?? 'success';
        if (behavior !== 'success') throw behavior.throw;
        return {
          imageBase64: fakePng('portrait').toString('base64'),
          mimeType: 'image/png',
          identity: { archetype: 'the-wanderer' },
        };
      }
      if (request.operation === 'soulmate_interpretation') {
        interpretationCalls++;
        return {
          personality: 'p', dynamic: 'd', attraction: 'a',
          challenge: 'c', meeting: 'm', feeling: 'f',
        };
      }
      throw new Error(`unexpected_operation_${request.operation}`);
    },
  };

  const processor = new ReadingProcessor(
    repository, flow, stagedRepository, stagedImages, results, ai, clock,
    notifier, false, providerStages, undefined, soulmateInputs, soulmatePortraits, entitlement,
  );

  const owner = identityKeyFromSubject('rejection-user');

  async function createDurable(sourceRequestId = 'rejection-01') {
    const operation = await operations.create({
      ownerUserId: owner, readingType: 'soulmate', sourceRequestId, executionMode: 'durable',
    });
    await flow.remember(operation);
    await soulmateInputs.save({
      ownerUserId: owner, operationId: operation.operationId,
      fields: { name: 'Ada', birthIso: '1995-03-02' },
    });
    clock.ms = operation.readyAtMs;
    return operation;
  }

  return {
    clock, repository, flow, results, notifier, processor, owner, providerStages, soulmatePortraits, entitlement,
    createDurable,
    portraitCalls: () => portraitCalls,
    interpretationCalls: () => interpretationCalls,
    queuePortrait: (b: PortraitBehavior) => { portraitQueue.push(b); },
  };
}

const rateLimited = (retryAfterMs?: number) =>
  new ProxyError(ErrorCode.rateLimited, 429, retryAfterMs != null ? { retryAfterMs } : undefined);

const rateLimitedWithEvidence = () =>
  new ProxyError(ErrorCode.rateLimited, 429, {
    retryAfterMs: 40_000,
    requestId: 'req_evidence_1',
    rateLimit: { 'x-ratelimit-remaining-requests': '0' },
    providerMessage: 'rate_limit_error | rate_limited | Too many requests',
  });

describe('SM-RL1/SM-RL2 explicit provider rejection recovery + safe backoff', () => {
  it('2: rate_limited on attempt #1, checkpoint becomes a known rejection (not ambiguous), retry permitted, attempt #2 succeeds', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);
    const stage = await h.providerStages.get(`${op.operationId}:portrait`);
    expect(stage.state).toBe('rejected_retryable');
    expect(stage.providerErrorCode).toBe('rate_limited');
    expect(stage.attemptCount).toBe(1);
    expect(stage.maxAttempts).toBe(3);

    // Backoff not yet elapsed — Cloud Tasks' own immediate redelivery must
    // NOT be allowed to call the provider again yet. Even a redelivery
    // well past the OLD 2s default (but short of the new 30s floor) must
    // still be blocked (SM-RL2 §4).
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);
    h.clock.ms += 5_000;
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);

    // SM-RL2 §4 — attempt #1 rejection floor is 30s minimum.
    h.clock.ms += 25_000; // total 30s since rejection
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(2);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).state).toBe('persisted');
    expect((await h.repository.getById(op.operationId))?.status).toBe('ready');
  });

  it('3: rate_limited twice, bounded retry, attempt #3 succeeds -> ready', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 30_000; // SM-RL2 §4 — attempt #1 rejection floor: 30s
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(2);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).attemptCount).toBe(2);

    h.clock.ms += 60_000; // SM-RL2 §4 — attempt #2 rejection floor: 60s
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(3);
    expect((await h.repository.getById(op.operationId))?.status).toBe('ready');
  });

  it('4: rate_limited until the retry budget is exhausted -> terminal controlled failure, no infinite retries', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });
    h.queuePortrait({ throw: rateLimited() });
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 30_000;
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 60_000;
    // Attempt #3 (the budget's last) also rejects.
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(3);

    // Budget spent — a further claim must fail closed, NEVER call the
    // provider a 4th time, no matter how much more time passes.
    h.clock.ms += 60_000;
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(3);
    expect((await h.repository.getById(op.operationId))?.status).toBe('failed');

    // Still terminal on yet another delivery.
    expect(await h.processor.process(op.operationId)).toBe('noop');
    expect(h.portraitCalls()).toBe(3);
  });

  it('5: rejection with no Retry-After — the 30s floor for attempt #1 is enforced, not shorter', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 29_000; // just under the 30s floor
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);

    h.clock.ms += 1_000; // total 30s
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(2);
  });

  it('5b: rejection with no Retry-After on attempt #2 — the 60s floor is enforced, not shorter', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 30_000;
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(2);

    h.clock.ms += 59_000; // just under the 60s floor
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(2);

    h.clock.ms += 1_000; // total 60s
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(3);
  });

  it('7: Retry-After=45s on attempt #1 -> honored (>=45s), NOT shortened to the 30s floor', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited(45_000) });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 30_000; // the floor has elapsed, but Retry-After asked for 45s
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);

    h.clock.ms += 15_000; // total 45s since rejection
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(2);
  });

  it('8: Retry-After=90s on attempt #2 -> honored (>=90s), NOT shortened to the 60s floor', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });
    h.queuePortrait({ throw: rateLimited(90_000) });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 30_000;
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(2);

    h.clock.ms += 60_000; // the 60s floor has elapsed, but Retry-After asked for 90s
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(2);

    h.clock.ms += 30_000; // total 90s since rejection
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(3);
  });

  it('6: provider timeout (408/AbortError-equivalent) stays ambiguous — NO automatic second call', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: new ProxyError(ErrorCode.providerTimeout, 408) });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).state).toBe('in_flight');

    h.clock.ms += 60_000;
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(1);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).state).toBe('provider_outcome_unknown');
  });

  it('7: network reset (TypeError-equivalent) stays ambiguous — NO automatic second call', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: new ProxyError(ErrorCode.network) });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 60_000;
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(1);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).state).toBe('provider_outcome_unknown');
  });

  it('8: process death after provider send (stale in_flight, no explicit rejection ever recorded) -> ambiguous, no automatic retry unless an artifact exists', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    // Simulate the process dying mid-call: claimAttempt already committed
    // in_flight, but nothing ever resolved it (no markRejected reached).
    await h.providerStages.claimAttempt(`${op.operationId}:portrait`, h.owner);

    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(0);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).state).toBe('provider_outcome_unknown');
  });

  it('10: Premium expires between a rate-limited attempt #1 and the retry -> attempt #2 is NEVER called', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);

    // Entitlement lapses before the retry window opens.
    h.entitlement.revoke(h.owner);
    h.clock.ms += 30_000;

    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(1);
    expect((await h.repository.getById(op.operationId))?.status).toBe('failed');
  });

  it('11: Premium still active before the retry -> retry permitted', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 30_000;
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(2);
  });

  it('12: duplicate Cloud Task delivery never exceeds the retry budget or fires a simultaneous second attempt', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });
    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    h.clock.ms += 30_000;

    // Two "simultaneous" redeliveries land at once.
    const outcomes = await Promise.allSettled([
      h.processor.process(op.operationId),
      h.processor.process(op.operationId),
    ]);
    expect(outcomes.filter((o) => o.status === 'fulfilled' && o.value === 'completed')).toHaveLength(1);
    expect(h.portraitCalls()).toBe(2); // attempt #1 (rejected) + attempt #2 (won the race), never 3
  });

  it('13: explicit nonretryable rejection (moderation) fails closed immediately, no automatic retry ever', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: new ProxyError(ErrorCode.moderationBlocked) });

    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(1);
    const stage = await h.providerStages.get(`${op.operationId}:portrait`);
    expect(stage.state).toBe('rejected_terminal');
    expect(stage.providerErrorCode).toBe('moderation_blocked');
    expect((await h.repository.getById(op.operationId))?.status).toBe('failed');

    h.clock.ms += 60_000;
    expect(await h.processor.process(op.operationId)).toBe('noop');
    expect(h.portraitCalls()).toBe(1);
  });

  it('13b: explicit nonretryable rejection (invalid_request) also fails closed immediately', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: new ProxyError(ErrorCode.invalidRequest) });

    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(1);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).state).toBe('rejected_terminal');
  });

  it('SM-RL2 §5: 429 evidence (request-id/rate-limit headers/provider message/Retry-After) is durably persisted on the checkpoint, not only logged', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimitedWithEvidence() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    const stage = await h.providerStages.get(`${op.operationId}:portrait`);
    expect(stage.state).toBe('rejected_retryable');
    expect(stage.requestId).toBe('req_evidence_1');
    expect(stage.rateLimit).toMatchObject({ 'x-ratelimit-remaining-requests': '0' });
    expect(stage.providerMessage).toContain('rate_limited');
    expect(stage.rawRetryAfterMs).toBe(40_000);
  });

  it('16: a portrait already durably persisted is never regenerated, even mid rate-limit retry window', async () => {
    const h = harness();
    h.entitlement.grant(h.owner);
    const op = await h.createDurable();
    h.queuePortrait({ throw: rateLimited() });

    await expect(h.processor.process(op.operationId)).rejects.toThrow();
    expect(h.portraitCalls()).toBe(1);

    // The object shows up durably (e.g. a delayed provider success that
    // raced the rejection classification) BEFORE the 30s retry window
    // would otherwise open.
    await h.soulmatePortraits.put({
      operationId: op.operationId,
      ownerUserId: h.owner,
      bytes: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3, 4]),
      contentType: 'image/png',
      identity: { archetype: 'the-wanderer' },
    });

    h.clock.ms += 30_000;
    expect(await h.processor.process(op.operationId)).toBe('completed');
    // Recovery-before-claimAttempt wins — no second provider call.
    expect(h.portraitCalls()).toBe(1);
    expect((await h.providerStages.get(`${op.operationId}:portrait`)).state).toBe('persisted');
  });
});

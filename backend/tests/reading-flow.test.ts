import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
  advance(ms: number): void {
    this.ms += ms;
  }
}

function setup() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'));
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 60_000, palm: 60_000, soulmate: 60_000 }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10 }));
  const flow = new ReadingFlow(store, clock, operations, ledger);
  return { store, clock, operations, ledger, flow };
}

describe('reading flow claim', () => {
  it('does not execute before eligibility and claims once after', async () => {
    const { operations, flow, clock } = setup();
    const owner = identityKeyFromSubject('user-a');
    const created = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: 'coffee-src-01',
    });
    await flow.remember(created);
    const early = await flow.claim(owner, created.operationId);
    expect(early.execute).toBe(false);
    expect(early.operation.status).toBe('waiting');
    clock.advance(60_000);
    const [first, second] = await Promise.all([
      flow.claim(owner, created.operationId),
      flow.claim(owner, created.operationId),
    ]);
    const executes = [first, second].filter((item) => item.execute);
    expect(executes).toHaveLength(1);
    expect((await operations.get(owner, created.operationId)).status).toBe('processing');
    const again = await flow.claim(owner, created.operationId);
    expect(again.execute).toBe(false);
  });

  it('recovers the same active operation and refunds an accelerated failure once', async () => {
    const { operations, flow, ledger } = setup();
    const owner = identityKeyFromSubject('user-a');
    await ledger.credit({
      ownerUserId: owner,
      amount: 20,
      idempotencyKey: 'seed-credit1',
    });
    const created = await operations.create({
      ownerUserId: owner,
      readingType: 'palm',
      sourceRequestId: 'palm-src-0001',
    });
    await flow.remember(created);
    const recovered = await flow.active(owner, 'palm');
    expect(recovered?.operationId).toBe(created.operationId);
    await ledger.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'accel-key-01',
    });
    const claimed = await flow.claim(owner, created.operationId);
    expect(claimed.execute).toBe(true);
    const failed = await flow.failFinal({
      ownerUserId: owner,
      operationId: created.operationId,
    });
    expect(failed.status).toBe('failed');
    expect(await ledger.balanceOf(owner)).toBe(20);
    const again = await flow.failFinal({
      ownerUserId: owner,
      operationId: created.operationId,
    });
    expect(again.status).toBe('failed');
    expect(await ledger.balanceOf(owner)).toBe(20);
  });
});

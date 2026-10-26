/**
 * Büyük Final Aşama 01 / F1 — the full lifecycle of a coffee reading whose
 * owner already used today's coffee allowance, after they paid gems to
 * accelerate it. Real ReadingProcessor, ReadingFlow, GemLedger and ritual
 * quota code over the in-memory document store; only the AI provider is a
 * counting fake (it must never be called). Measures current behavior; no
 * source is changed by this file.
 *
 * Expected: the operation ends `failed` with `failureCode: daily_quota`
 * and stays readable as such; the gem debit is refunded in full exactly
 * once, also across worker retries, concurrent workers and repeated
 * acceleration requests; another account is unaffected; and the outcome
 * is not silent in the worker log.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { toPublicStatus } from '../src/reading/operation-model.js';
import { SEED, world } from './support/coffee-quota-world.js';

describe('F1: coffee daily quota already used, reading accelerated with gems', () => {
  it('ends failed with daily_quota, readable as such, never calling the provider',
    async () => {
      const w = await world();
      const owner = identityKeyFromSubject('f1-owner-a');
      await w.useTodaysCoffee(owner);
      const opId = await w.acceleratedCoffee(owner, 'a1');
      expect(await w.ledger.balanceOf(owner)).toBeLessThan(SEED);

      await expect(w.processor.process(opId, w.log)).resolves.toBe('failed');

      expect(w.calls()).toBe(0);
      const record = await w.operations.get(owner, opId);
      expect(record.status).toBe('failed');
      expect(record.failureCode).toBe('daily_quota');
      // What the app polls: an explicit failure with its code, not a spinner.
      const view = toPublicStatus(record, w.clock.ms);
      expect(view).toMatchObject({
        status: 'failed',
        failureCode: 'daily_quota',
        resultReady: false,
        resultId: null,
        accelerated: true,
      });
    });

  it('refunds the gem debit in full, exactly once', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-b');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'b1');
    await w.processor.process(opId, w.log);
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
  });

  it('a retried worker run refunds nothing more and changes nothing', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-c');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'c1');
    await w.processor.process(opId, w.log);
    const again = await w.processor.process(opId, w.log);
    expect(again).not.toBe('completed');
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    expect((await w.operations.get(owner, opId)).failureCode).toBe('daily_quota');
    expect(w.calls()).toBe(0);
  });

  it('two concurrent worker runs refund exactly once', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-d');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'd1');
    await Promise.allSettled([
      w.processor.process(opId, w.log),
      w.processor.process(opId, w.log),
    ]);
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    expect((await w.operations.get(owner, opId)).status).toBe('failed');
  });

  it('accelerating the failed reading again, same key or new, never debits',
    async () => {
      const w = await world();
      const owner = identityKeyFromSubject('f1-owner-e');
      await w.useTodaysCoffee(owner);
      const opId = await w.acceleratedCoffee(owner, 'e1');
      await w.processor.process(opId, w.log);
      for (const key of ['f1-accelerate-e1', 'f1-accelerate-e1-retry']) {
        await w.ledger
          .accelerate({ ownerUserId: owner, operationId: opId, idempotencyKey: key })
          .catch(() => undefined);
      }
      expect(await w.ledger.balanceOf(owner)).toBe(SEED);
      expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    });

  it('another account is untouched and its coffee reaches the provider', async () => {
    const w = await world();
    const a = identityKeyFromSubject('f1-owner-f');
    const b = identityKeyFromSubject('f1-owner-g');
    await w.useTodaysCoffee(a);
    const opA = await w.acceleratedCoffee(a, 'f1');
    const opB = await w.acceleratedCoffee(b, 'g1');
    const balanceB = await w.ledger.balanceOf(b);
    await w.processor.process(opA, w.log);
    expect(await w.ledger.balanceOf(b)).toBe(balanceB);
    expect(w.transactionsFor(opB)).toEqual(['spend']);
    await w.processor.process(opB, w.log);
    // A's quota does not apply to B: B's reading is admitted to the
    // provider. (The counting fake returns no valid coffee payload, so B
    // then ends at the existing legacy terminal check; that outcome is the
    // fake's, never daily_quota.)
    expect(w.calls()).toBe(1);
    expect((await w.operations.get(b, opB)).failureCode).not.toBe('daily_quota');
    expect(await w.ledger.balanceOf(a)).toBe(SEED);
    expect(w.transactionsFor(opA)).toEqual(['refund', 'spend']);
  });

  it('V3 (2 cups + 1 saucer): failed daily_quota, refunded once, provider '
    + 'never reached, the three views cleaned', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-v3');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffeeV3(owner, 'v3a');
    expect(w.objects.objects.size).toBe(3);
    expect(await w.ledger.balanceOf(owner)).toBeLessThan(SEED);

    await expect(w.processor.process(opId, w.log)).resolves.toBe('failed');
    await w.processor.process(opId, w.log);

    expect(w.v3Calls()).toBe(0);
    expect(w.calls()).toBe(0);
    const record = await w.operations.get(owner, opId);
    expect(record).toMatchObject({ status: 'failed', failureCode: 'daily_quota' });
    expect(toPublicStatus(record, w.clock.ms)).toMatchObject({
      status: 'failed',
      failureCode: 'daily_quota',
      resultReady: false,
      accelerated: true,
    });
    expect(await w.ledger.balanceOf(owner)).toBe(SEED);
    expect(w.transactionsFor(opId)).toEqual(['refund', 'spend']);
    expect(w.objects.objects.size).toBe(0);
  });

  // F1 FAIL (current code, reading-processor-execute.ts ritual 'reply'
  // branch): the daily_quota exit writes no log event, unlike every other
  // terminal exit. Marked `it.fails` so the suite records the defect; when
  // the log is added this flips to a failure and must become `it`.
  it.fails('[F1 FAIL] the daily_quota outcome is not silent: the worker logs it', async () => {
    const w = await world();
    const owner = identityKeyFromSubject('f1-owner-h');
    await w.useTodaysCoffee(owner);
    const opId = await w.acceleratedCoffee(owner, 'h1');
    await w.processor.process(opId, w.log);
    const ours = w.logs.filter((l) => l.operationId === opId);
    // Every other terminal exit logs an event naming its outcome
    // (coffee_v3_terminal_failure, spend_guard_rejected,
    // provider_outcome_unknown). This one must too.
    expect(
      ours.some((l) => JSON.stringify(l).includes('daily_quota')),
      `worker log for the op: ${JSON.stringify(ours.map((l) => l.event))}`,
    ).toBe(true);
  });
});

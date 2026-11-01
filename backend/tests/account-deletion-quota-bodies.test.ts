/**
 * Account deletion x free-quota attempt records. `ritualDailyQuotaAttempts`
 * (Coffee / Palm / Dream / Astrology) and `freeTextQuotaAttempts` (chat,
 * oracle, Yıldızname, free tarot) keep the delivered response `body`, owned
 * by an `identity` field (not `ownerUserId`); their day counters carry the
 * same field. Deleting A removes A's attempts and counters and keeps B's;
 * repeat / interrupted runs behave; and once A's deletion barrier exists no
 * admission or settlement writes A's records again, so a reading finishing
 * during or after the sweep cannot leave its text behind.
 *
 * Real quota writers, real deletion repository, in-memory store. No AI.
 */
import { describe, expect, it } from 'vitest';
import { ACCOUNT_DELETION_RECEIPTS, accountDeletionReceiptId } from '../src/account/deletion-barrier.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import type { ServerClock } from '../src/reading/clock.js';
import { admitFreeTextQuota, failFreeTextQuota, finishFreeTextQuota } from '../src/reading/free-text-quota.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { admitRitualQuota } from '../src/reading/ritual-daily-quota.js';
import { failRitualQuota, finishRitualQuota } from '../src/reading/ritual-daily-quota-settle.js';
import type { OpenAiFetch } from '../src/types.js';
import { realDeletion } from './support/deletion-adapter.js';
import { authHeader, chatBody, signHs256, testApp, testConfig } from './helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date { return new Date(this.ms); }
}

const SECRET = 'unit-test-jwt-secret';
const A = identityKeyFromSubject('user-a');
const B = identityKeyFromSubject('user-b');
const RITUAL = ['ritualDailyQuota', 'ritualDailyQuotaAttempts'] as const;
const FREE_TEXT = ['freeTextQuota', 'freeTextQuotaAttempts'] as const;
const ALL = [...RITUAL, ...FREE_TEXT] as const;
const READING = { success: true, data: { overall: 'kişisel fal metni' } };

function world() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-27T10:00:00Z'));
  const config = testConfig();
  const { adapter, deletion } = realDeletion(store);
  const docsOf = (collection: string, owner: string) => [...store.docs.entries()]
    .filter(([path, data]) => path.startsWith(`${collection}/`) && data.identity === owner);
  const owned = (owner: string) => Object.fromEntries(ALL.map((c) => [c, docsOf(c, owner).length]));
  const bodies = (owner: string) => ALL.flatMap((c) => docsOf(c, owner))
    .filter(([, data]) => typeof data.body === 'string').length;
  const receipt = (owner: string) =>
    store.docs.get(`${ACCOUNT_DELETION_RECEIPTS}/${accountDeletionReceiptId(owner)}`) as Record<string, unknown> | undefined;

  const ritual = (owner: string, key: string, operation = 'coffee_analysis') => admitRitualQuota({
    config, store, clock, operation, identity: owner, idempotencyKey: key,
  });
  const freeText = (owner: string, key: string) => admitFreeTextQuota({
    config, store, clock, operation: 'chat', paidTarot: false, identity: owner, idempotencyKey: key,
  });

  /** One delivered Coffee reading and one delivered chat answer for `owner`. */
  async function delivered(owner: string, tag: string) {
    const r = await ritual(owner, `ritual-${tag}-key`);
    if (r.action !== 'hold') throw new Error(`setup ritual: ${r.action}`);
    await finishRitualQuota(store, owner, r.hold, READING);
    const f = await freeText(owner, `chat-${tag}-key01`);
    if (f.action !== 'hold') throw new Error(`setup free text: ${f.action}`);
    await finishFreeTextQuota(store, owner, f.hold, READING);
  }

  async function barrier(owner: string) {
    await store.runTransaction(async (tx) => {
      tx.set(store.collection(ACCOUNT_DELETION_RECEIPTS).doc(accountDeletionReceiptId(owner)), {
        receiptId: accountDeletionReceiptId(owner), status: 'deleting',
      });
    });
  }

  return { store, clock, config, adapter, deletion, owned, bodies, receipt, ritual, freeText, delivered, barrier };
}

const none = Object.fromEntries(ALL.map((c) => [c, 0]));

describe('deleting A removes A\'s quota attempts (with their text) and counters, keeps B\'s', () => {
  it('A\'s delivered Coffee reading and chat answer are gone; B still replays its own', async () => {
    const w = world();
    await w.delivered(A, 'a1');
    await w.delivered(B, 'b1');
    expect(w.bodies(A)).toBe(2);
    const receipt = await w.deletion.deleteForIdentity(A);
    expect(receipt.status).toBe('accepted');
    expect(w.owned(A)).toEqual(none);
    expect(w.bodies(B)).toBe(2);
    expect((await w.ritual(B, 'ritual-b1-key')).action).toBe('stored');
    expect(await w.freeText(B, 'chat-b1-key01')).toMatchObject({ action: 'reply', status: 200, payload: READING });
  });

  it('more than one batch (450 attempts per collection) is fully removed', async () => {
    const w = world();
    await w.store.runTransaction(async (tx) => {
      for (const collection of ALL) {
        for (let i = 0; i < 450; i++) {
          tx.set(w.store.collection(collection).doc(`${collection}-a-${i}`), { identity: A, body: 'x', status: 'final' });
        }
        tx.set(w.store.collection(collection).doc(`${collection}-b`), { identity: B, body: 'y', status: 'final' });
      }
    });
    await w.deletion.deleteForIdentity(A);
    expect(w.owned(A)).toEqual(none);
    expect(w.owned(B)).toEqual(Object.fromEntries(ALL.map((c) => [c, 1])));
  });

  it('a repeated deletion is a no-op; an interrupted one is never accepted and the retry finishes', async () => {
    const w = world();
    await w.delivered(A, 'a1');
    await w.delivered(B, 'b1');
    w.adapter.failOnce = 'freeTextQuotaAttempts';
    await expect(w.deletion.deleteForIdentity(A)).rejects.toThrow(/injected failure/);
    expect(w.receipt(A)?.status).toBe('deleting');
    expect(w.owned(A).freeTextQuotaAttempts).toBe(1);
    const retried = await w.deletion.deleteForIdentity(A);
    expect(retried.status).toBe('accepted');
    const again = await w.deletion.deleteForIdentity(A);
    expect(again.receiptId).toBe(retried.receiptId);
    expect(w.owned(A)).toEqual(none);
    expect(w.bodies(B)).toBe(2);
  });
});

describe('no record of A is written behind the deletion barrier', () => {
  it('a reading that finishes while the deletion runs leaves no text (barrier before the sweep)', async () => {
    const w = world();
    const r = await w.ritual(A, 'inflight-ritual-key');
    const f = await w.freeText(A, 'inflight-chat-key1');
    if (r.action !== 'hold' || f.action !== 'hold') throw new Error('setup');
    await w.barrier(A);
    await finishRitualQuota(w.store, A, r.hold, READING);
    await finishFreeTextQuota(w.store, A, f.hold, READING);
    expect(w.bodies(A)).toBe(0);
    await w.deletion.deleteForIdentity(A);
    expect(w.owned(A)).toEqual(none);
  });

  it('a settlement after the sweep recreates nothing (finish and fail)', async () => {
    const w = world();
    const r = await w.ritual(A, 'late-ritual-key01');
    const f = await w.freeText(A, 'late-chat-key0001');
    const r2 = await w.ritual(A, 'late-ritual-key02', 'dream_analysis');
    if (r.action !== 'hold' || f.action !== 'hold' || r2.action !== 'hold') throw new Error('setup');
    await w.deletion.deleteForIdentity(A);
    await finishRitualQuota(w.store, A, r.hold, READING);
    await finishFreeTextQuota(w.store, A, f.hold, READING);
    await failRitualQuota(w.store, A, r2.hold);
    await failFreeTextQuota(w.store, A, f.hold);
    expect(w.owned(A)).toEqual(none);
  });

  it('a new admission for A during or after deletion is refused and writes nothing', async () => {
    for (const phase of ['deleting', 'accepted'] as const) {
      const w = world();
      if (phase === 'deleting') await w.barrier(A);
      else await w.deletion.deleteForIdentity(A);
      await expect(w.ritual(A, 'after-ritual-key01')).rejects.toThrow(/account_deleted/);
      await expect(w.freeText(A, 'after-chat-key0001')).rejects.toThrow(/account_deleted/);
      expect(w.owned(A)).toEqual(none);
      // B is not affected by A's barrier.
      expect((await w.ritual(B, 'b-ritual-key-0001')).action).toBe('hold');
      expect((await w.freeText(B, 'b-chat-key-000001')).action).toBe('hold');
    }
  });

  it('deletion racing settlements: whatever the order, no text of A survives', async () => {
    for (let round = 0; round < 10; round++) {
      const w = world();
      const holds = await Promise.all(Array.from({ length: 3 }, (_, i) => w.ritual(A, `race-ritual-key-${round}-${i}`, 'dream_analysis')));
      await w.delivered(B, `b${round}`);
      await Promise.all([
        w.deletion.deleteForIdentity(A),
        ...holds.map((h) => (h.action === 'hold' ? finishRitualQuota(w.store, A, h.hold, READING) : Promise.resolve())),
      ]);
      expect(w.owned(A)).toEqual(none);
      expect(w.bodies(B)).toBe(2);
    }
  });
});

describe('route: a deleted account gets no new free answer', () => {
  it('/v1/ai/complete chat after deletion: refused, no provider call, nothing stored', async () => {
    const w = world();
    let calls = 0;
    const fetchImpl: OpenAiFetch = async () => { calls += 1; throw new Error('no real AI'); };
    await w.deletion.deleteForIdentity(A);
    const app = await testApp(testConfig({ AI_JWT_SECRET: SECRET }), fetchImpl, {
      freeTextQuotaStore: w.store, ritualQuotaStore: w.store,
    });
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(signHs256(SECRET, { sub: 'user-a' })), 'idempotency-key': 'deleted-chat-0001' },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json()).toEqual({ success: false, error: { code: 'unauthorized' } });
    expect(calls).toBe(0);
    expect(w.owned(A)).toEqual(none);
    await app.close();
  });
});

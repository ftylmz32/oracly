import { describe, expect, it } from 'vitest';
import { ErrorCode, ProxyError } from '../src/errors.js';
import { FirestoreSpendGuard } from '../src/ai/spend-guard.js';
import { quoteChat, quoteSpeech } from '../src/ai/spend-quote.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { OpenAiTransport } from '../src/ai/openai-transport.js';
import { testConfig } from './helpers.js';

const DAY = new Date('2026-10-20T12:00:00Z');

function guard(cap = 5_000_000, killed = false) {
  const store = new MemoryDocumentStore();
  return {
    store,
    guard: new FirestoreSpendGuard(store, cap, killed, () => DAY),
  };
}

describe('ai spend guard', () => {
  it('rejects a second concurrent reservation that would pass the cap', async () => {
    const { guard: spend } = guard();
    const first = spend.reserve({ key: 'a', ceilingMicros: 3_000_000 });
    const second = spend.reserve({ key: 'b', ceilingMicros: 3_000_000 });
    const results = await Promise.allSettled([first, second]);
    const rejected = results.filter((row) => row.status === 'rejected');
    expect(rejected).toHaveLength(1);
    expect((rejected[0] as PromiseRejectedResult).reason).toBeInstanceOf(ProxyError);
    expect(((rejected[0] as PromiseRejectedResult).reason as ProxyError).code).toBe(ErrorCode.spendGuard);
  });

  it('does not reserve the same key twice', async () => {
    const { store, guard: spend } = guard();
    await spend.reserve({ key: 'same', ceilingMicros: 2_000_000 });
    await spend.reserve({ key: 'same', ceilingMicros: 2_000_000 });
    expect(store.read('aiSpendDays/2026-10-20').data()?.totalMicros).toBe(2_000_000);
  });

  it('keeps the ceiling when the provider outcome is unknown and lowers it when usage is known', async () => {
    const { store, guard: spend } = guard();
    await spend.reserve({ key: 'lost', ceilingMicros: 1_000_000 });
    await spend.settle({ key: 'lost', actualMicros: null });
    expect(store.read('aiSpendDays/2026-10-20').data()?.totalMicros).toBe(1_000_000);
    await spend.reserve({ key: 'known', ceilingMicros: 1_000_000 });
    await spend.settle({ key: 'known', actualMicros: 250_000 });
    expect(store.read('aiSpendDays/2026-10-20').data()?.totalMicros).toBe(1_250_000);
  });

  it('does not call the provider when the cap or the model price is closed', async () => {
    const { guard: spend } = guard(100, true);
    const fetchImpl = async () => {
      throw new Error('provider_called');
    };
    const transport = new OpenAiTransport(testConfig(), fetchImpl, spend);
    await expect(transport.complete({
      model: 'gpt-4o',
      messages: [{ role: 'user', content: 'hi' }],
      reservationKey: 'kill',
    })).rejects.toMatchObject({ code: ErrorCode.spendGuard });
    const priced = new FirestoreSpendGuard(new MemoryDocumentStore(), 5_000_000, false, () => DAY);
    const closed = new OpenAiTransport(testConfig(), fetchImpl, priced);
    await expect(closed.complete({
      model: 'not-a-priced-model',
      messages: [{ role: 'user', content: 'hi' }],
      reservationKey: 'unknown',
    })).rejects.toMatchObject({ code: ErrorCode.spendGuard });
  });

  it('prices published models and leaves mini-tts unpriced', () => {
    const astra = quoteChat('gpt-6-astra', [{ role: 'user', content: 'rüya' }]);
    expect('ceilingMicros' in astra && astra.ceilingMicros > 5_000_000).toBe(true);
    const chat = quoteChat('gpt-4o', [{ role: 'user', content: 'merhaba' }]);
    expect('ceilingMicros' in chat && chat.ceilingMicros < 5_000_000).toBe(true);
    expect(quoteSpeech('gpt-4o-mini-tts', 40)).toEqual({ unpriced: 'unpriced_output' });
    expect(quoteSpeech('tts-1-hd', 100)).toEqual({ ceilingMicros: 3_000 });
  });
});

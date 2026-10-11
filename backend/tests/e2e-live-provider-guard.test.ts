/**
 * Slice 6 — the real-provider acceptance guard must fail closed BEFORE any
 * request leaves the process. Exercised against a fake fetch only: zero
 * network, zero provider calls.
 */
import { describe, expect, it } from 'vitest';
import {
  LiveProviderBudgetError,
  OFFICIAL_OPENAI_BASE_URL,
  createLiveProviderGuard,
} from './e2e/live-provider-guard.js';

const ENDPOINT = `${OFFICIAL_OPENAI_BASE_URL}/chat/completions`;

function fakeFetch(mode: 'ok' | 'throw' = 'ok') {
  const seen: Array<{ url: string; headers: Record<string, string> }> = [];
  const fetch = async (url: string | URL | Request, init?: RequestInit) => {
    seen.push({ url: String(url), headers: { ...(init?.headers as Record<string, string>) } });
    if (mode === 'throw') throw new Error('socket hang up');
    return new Response(JSON.stringify({ choices: [{ message: { content: '{}' } }], usage: { prompt_tokens: 11, completion_tokens: 7, total_tokens: 18 } }), { status: 200 });
  };
  return { fetch, seen };
}

const init = (body: Record<string, unknown>): RequestInit => ({
  method: 'POST',
  headers: { Authorization: 'Bearer sk-live-SECRET-never-recorded', 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});
const observer = () =>
  init({
    model: 'gpt-5.6-sol',
    response_format: { type: 'json_schema', json_schema: { name: 'coffee_v3_observation' } },
    messages: [{ role: 'user', content: [1, 2, 3, 4].map(() => ({ type: 'image_url', image_url: { url: 'data:image/jpeg;base64,AAAA' } })) }],
  });
const writer = () => init({ model: 'gpt-5.6-sol', response_format: { type: 'json_object' }, messages: [] });

describe('Slice 6 live-provider guard', () => {
  it('only the official endpoint may ever be configured or called', async () => {
    const { fetch, seen } = fakeFetch();
    expect(() => createLiveProviderGuard({ realFetch: fetch, baseUrl: 'https://evil.example/v1' })).toThrow(LiveProviderBudgetError);
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    await expect(g.fetch('https://evil.example/v1/chat/completions', observer())).rejects.toThrow(/endpoint_not_allowed/);
    await expect(g.fetch(`${OFFICIAL_OPENAI_BASE_URL}/images/generations`, observer())).rejects.toThrow(/endpoint_not_allowed/);
    expect(seen).toHaveLength(0);
  });

  it('limits cannot be raised above the owner authorization', () => {
    const { fetch } = fakeFetch();
    for (const over of [{ maxTotal: 7 }, { maxAttempts: 3 }, { maxObserverPerAttempt: 2 }, { maxWriterPerAttempt: 3 }]) {
      expect(() => createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL, ...over })).toThrow(/limits_above_authorization/);
    }
  });

  it('only V3 observer / writer requests are allowed; a writer needs an open attempt', async () => {
    const { fetch, seen } = fakeFetch();
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    await expect(g.fetch(ENDPOINT, init({ model: 'gpt-4o', messages: [] }))).rejects.toThrow(/request_kind_not_allowed/);
    await expect(
      g.fetch(ENDPOINT, init({ response_format: { type: 'json_schema', json_schema: { name: 'coffee_v2_observation' } } })),
    ).rejects.toThrow(/request_kind_not_allowed/);
    await expect(g.fetch(ENDPOINT, writer())).rejects.toThrow(/writer_without_attempt/);
    expect(seen).toHaveLength(0);
  });

  it('per attempt: 1 observer + 2 writers; at most 2 attempts and 6 requests in total', async () => {
    const { fetch, seen } = fakeFetch();
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    await g.fetch(ENDPOINT, observer());
    await g.fetch(ENDPOINT, writer());
    await g.fetch(ENDPOINT, writer());
    await expect(g.fetch(ENDPOINT, writer())).rejects.toThrow(/writer_budget_exhausted/);
    await g.fetch(ENDPOINT, observer()); // attempt 2
    await g.fetch(ENDPOINT, writer());
    await g.fetch(ENDPOINT, writer());
    await expect(g.fetch(ENDPOINT, observer())).rejects.toThrow(/total_budget_exhausted|attempt_budget_exhausted/);
    expect(seen).toHaveLength(6);
    expect(g.attempts()).toBe(2);
    const records = g.records();
    expect(records.map((r) => `${r.attempt}:${r.kind}`)).toEqual([
      '1:observer', '1:writer', '1:writer', '2:observer', '2:writer', '2:writer',
    ]);
    expect(records[0]).toMatchObject({ model: 'gpt-5.6-sol', imageCount: 4, status: 200, outcome: 'ok', usage: { totalTokens: 18 } });
    // Metadata only: never the credential, never content.
    expect(JSON.stringify(records)).not.toMatch(/SECRET|Bearer|base64|choices/);
  });

  it('a third attempt is refused even with requests left', async () => {
    const { fetch } = fakeFetch();
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    await g.fetch(ENDPOINT, observer());
    await g.fetch(ENDPOINT, observer());
    await expect(g.fetch(ENDPOINT, observer())).rejects.toThrow(/attempt_budget_exhausted/);
    expect(g.records()).toHaveLength(2);
  });

  it('an ambiguous upstream outcome seals the guard: no retry, nothing further', async () => {
    const { fetch, seen } = fakeFetch('throw');
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    await expect(g.fetch(ENDPOINT, observer())).rejects.toThrow(/socket hang up/);
    expect(g.sealed()).toBe('ambiguous_upstream_outcome');
    expect(g.records()[0].outcome).toBe('ambiguous');
    await expect(g.fetch(ENDPOINT, observer())).rejects.toThrow(/sealed/);
    await expect(g.fetch(ENDPOINT, writer())).rejects.toThrow(/sealed/);
    expect(seen).toHaveLength(1); // the possibly-billed request is counted, never repeated
  });

  it('seal() at test end blocks every later request', async () => {
    const { fetch, seen } = fakeFetch();
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    g.seal();
    await expect(g.fetch(ENDPOINT, observer())).rejects.toThrow(/sealed:test_finished/);
    expect(seen).toHaveLength(0);
  });
});

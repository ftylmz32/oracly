/**
 * Slice 6 — the real-provider acceptance guard must fail closed BEFORE any
 * request leaves the process. Exercised against a fake fetch only: zero
 * network, zero provider calls.
 */
import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import {
  COFFEE_V3_LIVE_IMAGE_COUNT,
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
const observer = (images = 3) =>
  init({
    model: 'gpt-5.6-sol',
    response_format: { type: 'json_schema', json_schema: { name: 'coffee_v3_observation' } },
    messages: [{ role: 'user', content: Array.from({ length: images }, () => ({ type: 'image_url', image_url: { url: 'data:image/jpeg;base64,AAAA' } })) }],
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
    expect(records[0]).toMatchObject({ model: 'gpt-5.6-sol', imageCount: 3, status: 200, outcome: 'ok', usage: { totalTokens: 18 } });
    // No system message on this fake observer body → null; a writer with one records only its sha.
    expect(records[0].systemPromptSha256).toBeNull();
    // Metadata only: never the credential, never content.
    expect(JSON.stringify(records)).not.toMatch(/SECRET|Bearer|base64|choices/);
  });

  it('the observer request must carry exactly three images (two cup + saucer); a writer none — refused before sending', async () => {
    expect(COFFEE_V3_LIVE_IMAGE_COUNT).toBe(3);
    const { fetch, seen } = fakeFetch();
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    for (const n of [0, 1, 2, 4]) await expect(g.fetch(ENDPOINT, observer(n))).rejects.toThrow(/observer_image_count/);
    expect(seen).toHaveLength(0);
    expect(g.attempts()).toBe(0); // a refused request never consumes an attempt
    await g.fetch(ENDPOINT, observer());
    await expect(
      g.fetch(ENDPOINT, init({ model: 'gpt-5.6-sol', response_format: { type: 'json_object' }, messages: [{ role: 'user', content: [{ type: 'image_url', image_url: { url: 'x' } }] }] })),
    ).rejects.toThrow(/writer_with_images/);
    expect(seen).toHaveLength(1);
  });

  it('records the sha256 of the system prompt (which writer contract ran), never its content', async () => {
    const { fetch } = fakeFetch();
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    await g.fetch(ENDPOINT, observer());
    await g.fetch(ENDPOINT, init({ model: 'gpt-5.6-sol', response_format: { type: 'json_object' }, messages: [{ role: 'system', content: 'SECRET-PROMPT-TEXT' }, { role: 'user', content: 'x' }] }));
    const writer = g.records()[1];
    expect(writer.systemPromptSha256).toBe(createHash('sha256').update('SECRET-PROMPT-TEXT', 'utf8').digest('hex'));
    expect(JSON.stringify(g.records())).not.toContain('SECRET-PROMPT-TEXT');
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

  describe('writer-only replay of a recorded observation', () => {
    it('refuses every observer request before sending (no image ever leaves)', async () => {
      const { fetch, seen } = fakeFetch();
      const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL, writerOnly: true });
      await expect(g.fetch(ENDPOINT, observer())).rejects.toThrow(/observer_not_allowed_writer_only/);
      expect(seen).toHaveLength(0);
      expect(g.attempts()).toBe(0);
    });

    it('one attempt, at most two writer requests in total; a third is refused', async () => {
      const { fetch, seen } = fakeFetch();
      const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL, writerOnly: true });
      await g.fetch(ENDPOINT, writer());
      await g.fetch(ENDPOINT, writer());
      await expect(g.fetch(ENDPOINT, writer())).rejects.toThrow(/budget_exhausted/);
      await expect(g.fetch(ENDPOINT, observer())).rejects.toThrow(/live_provider_refused/);
      expect(seen).toHaveLength(2);
      expect(g.attempts()).toBe(1);
      expect(g.records().map((r) => [r.kind, r.attempt, r.imageCount])).toEqual([['writer', 1, 0], ['writer', 1, 0]]);
    });

    it('the writer-only budget cannot be raised and a writer still carries no image', async () => {
      const { fetch, seen } = fakeFetch();
      const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL, writerOnly: true, maxTotal: 6 });
      const withImage = init({
        model: 'gpt-5.6-sol',
        response_format: { type: 'json_object' },
        messages: [{ role: 'user', content: [{ type: 'image_url', image_url: { url: 'data:image/jpeg;base64,AAAA' } }] }],
      });
      await expect(g.fetch(ENDPOINT, withImage)).rejects.toThrow();
      await g.fetch(ENDPOINT, writer());
      await g.fetch(ENDPOINT, writer());
      await expect(g.fetch(ENDPOINT, writer())).rejects.toThrow(/budget_exhausted/);
      expect(seen).toHaveLength(2);
    });

    it('an ambiguous writer outcome still seals the guard', async () => {
      const { fetch, seen } = fakeFetch('throw');
      const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL, writerOnly: true });
      await expect(g.fetch(ENDPOINT, writer())).rejects.toThrow();
      await expect(g.fetch(ENDPOINT, writer())).rejects.toThrow(/sealed/);
      expect(seen).toHaveLength(1);
    });
  });

  it('keeps every writer text verbatim for the local evidence (hash = the pipeline hash), never an observer body or a header', async () => {
    const { fetch } = fakeFetch();
    const g = createLiveProviderGuard({ realFetch: fetch, baseUrl: OFFICIAL_OPENAI_BASE_URL });
    await g.fetch(ENDPOINT, observer());
    await g.fetch(ENDPOINT, writer());
    const outputs = g.writerOutputs();
    expect(outputs).toEqual([{ index: 2, attempt: 1, outputSha256: createHash('sha256').update('{}', 'utf8').digest('hex'), text: '{}' }]);
    expect(JSON.stringify(outputs)).not.toContain('sk-live-SECRET');
    // The request records stay metadata-only.
    for (const r of g.records()) expect(r).not.toHaveProperty('text');
  });
});

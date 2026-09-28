import { readFileSync } from 'node:fs';
import { loadConfig } from '../src/config.js';
import type { OpenAiFetch } from '../src/types.js';
import { deployedOpenAiEnv } from '../scripts/dream-phase4c/production-config.js';

export const FAKE_KEY = 'sk-phase4c2-FAKE-0123456789';
export const fakeConfig = () => loadConfig({ ...deployedOpenAiEnv(), OPENAI_API_KEY: FAKE_KEY });

const frozen = JSON.parse(
  readFileSync(new URL('../../docs/product/dream/evals/DREAM_PHASE4C_LIVE_RUN_20260928.json', import.meta.url), 'utf8'),
) as { runs: Array<{ runId: string; rawProviderText: string }> };

/** A frozen 4C live body (read only). */
export const frozenRaw = (runId: string) => frozen.runs.find((r) => r.runId === runId)!.rawProviderText;

export type Sent = { url: string; body: Record<string, unknown>; headers: Record<string, string> };

export function completion(model: string, content: string | null) {
  return new Response(
    JSON.stringify({
      model: `${model}-snapshot`,
      service_tier: 'default',
      choices: [{ finish_reason: 'stop', message: { content } }],
      usage: {
        prompt_tokens: 3000,
        completion_tokens: 700,
        prompt_tokens_details: { cached_tokens: 1024, cache_write_tokens: 0 },
        completion_tokens_details: { reasoning_tokens: model === 'gpt-4o' ? 0 : 300 },
      },
    }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
}

/** Records every request; [respond] decides the reply per call. */
export function fakeFetch(respond: (body: Record<string, unknown>, n: number) => Response | Promise<Response>) {
  const sent: Sent[] = [];
  const fetch: OpenAiFetch = async (input, init) => {
    const body = JSON.parse(String(init?.body)) as Record<string, unknown>;
    sent.push({ url: String(input), body, headers: (init?.headers ?? {}) as Record<string, string> });
    return respond(body, sent.length);
  };
  return { fetch, sent };
}

export const httpError = (status: number, message: string) =>
  new Response(JSON.stringify({ error: { type: 'invalid_request_error', message } }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

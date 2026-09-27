import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { AppLanguage } from '../src/ai/app-language.js';
import type { DreamAcceptanceInput } from '../src/ai/dream-acceptance.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import type { OpenAiFetch } from '../src/types.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

/** Synthetic premium fixtures shared with the Flutter parity test. */
export type DreamGolden = {
  id: string;
  language: AppLanguage;
  narrative: string;
  memorySummary?: string;
  data: DreamData;
};

export const goldens: DreamGolden[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./fixtures/dream-premium-golden.json', import.meta.url)), 'utf8'),
);

export const golden = (id: string): DreamGolden => goldens.find((g) => g.id === id)!;

export function acceptanceInput(g: DreamGolden): DreamAcceptanceInput {
  return {
    narrative: g.narrative,
    symbols: [],
    emotions: [],
    language: g.language,
    memorySummary: g.memorySummary,
  };
}

/** One route request against a scripted provider; counts provider calls. */
export async function serveDream(
  reply: DreamData,
  payload: Record<string, unknown>,
  key: string,
  deps: Parameters<typeof testApp>[2] = {},
) {
  let calls = 0;
  const fetch: OpenAiFetch = async () => {
    calls++;
    return jsonResponse({ choices: [{ message: { content: JSON.stringify(reply) } }] });
  };
  const app = await testApp(testConfig(), fetch, deps);
  const res = await app.inject({
    method: 'POST',
    url: '/v1/ai/complete',
    headers: { ...authHeader(), 'idempotency-key': key },
    payload: { operation: 'dream_analysis', payload },
  });
  await app.close();
  return { json: res.json(), calls };
}

export function goldenPayload(g: DreamGolden): Record<string, unknown> {
  return {
    narrative: g.narrative,
    language: g.language,
    ...(g.memorySummary ? { memorySummary: g.memorySummary } : {}),
  };
}

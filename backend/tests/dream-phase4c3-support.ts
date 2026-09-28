// Dream Phase 4C.3 — shared fixtures: configs derived from the deploy script,
// the 4C.2 request matrix and a recording fake provider (never the network).
import { AiProxyService } from '../src/ai/service.js';
import { loadConfig, type AppConfig } from '../src/config.js';
import { deployedOpenAiEnv } from '../scripts/dream-phase4c/production-config.js';
import { validated } from '../scripts/dream-phase4c2/harness.js';
import { buildPhase4c2Matrix, loadPhase4c2Requests } from '../scripts/dream-phase4c2/matrix.js';
import { completion, fakeFetch, frozenRaw } from './dream-phase4c2-support.js';

export const FAKE_KEY = 'sk-phase4c3-FAKE-0123456789';
export const ASTRA = { OPENAI_DREAM_MODEL: 'gpt-6-astra', OPENAI_DREAM_REASONING_EFFORT: 'medium' };
export const NO_DREAM = { OPENAI_DREAM_MODEL: '', OPENAI_DREAM_REASONING_EFFORT: '' };

/** Deploy-script env with [overrides]; empty strings behave as unset. */
export function configWith(overrides: Record<string, string> = {}): AppConfig {
  return loadConfig({ ...deployedOpenAiEnv(), OPENAI_API_KEY: FAKE_KEY, ...overrides });
}

export const attempts = buildPhase4c2Matrix(loadPhase4c2Requests());
/** One attempt per 4C.2 case (the Astra rotation slot). */
export const astraAttempts = attempts.filter((a) => a.candidate === 'gpt-6-astra');
export const trFear = astraAttempts.find((a) => a.caseId === 'tr-negated-fear')!;
export const passRaw = frozenRaw('tr-negated-fear');

/** One `AiProxyService` Dream call against a recording fake provider. */
export async function dreamCall(config: AppConfig, hint: unknown, attempt = trFear) {
  const fake = fakeFetch((body) => completion(String(body.model), passRaw));
  const service = new AiProxyService(config, fake.fetch);
  const outcome = await service
    .handle(validated(attempt), hint)
    .then(() => 'PASS', (e: { code?: string }) => e.code ?? 'THROWN');
  return { outcome, sent: fake.sent, body: fake.sent[0]?.body };
}

/**
 * Dream Phase 4C.2 — runs the 27 attempts through the production-mirroring
 * adapter over the real `OpenAiTransport`. One call per attempt, no retry,
 * no substitution, hard cap before the network. HTTP failures are recorded
 * as infrastructure outcomes, never as model quality.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import { OpenAiTransport } from '../../src/ai/openai-transport.js';
import { validateAiBody, type ValidatedRequest } from '../../src/ai/validate-request.js';
import type { AppConfig } from '../../src/config.js';
import { ProxyError } from '../../src/errors.js';
import type { OpenAiFetch } from '../../src/types.js';
import { budgetFetch, Phase4cBudgetExceeded } from '../dream-phase4c/budget-fetch.js';
import { memorySent, runDreamCandidate } from './adapter.js';
import { candidate as candidateOf } from './candidates.js';
import { PHASE4C2_MAX_CALLS, type Phase4c2Attempt } from './matrix.js';
import { buildRecord, type Phase4c2Record, type WireFacts } from './record.js';
import { PHASE4C2_WRITER_REVISION } from './record-type.js';
import { classifyPhase4c2 } from './stages.js';

/** Non-secret wire facts: request body keys and the response service tier. */
function observeFetch(inner: OpenAiFetch) {
  let last: WireFacts | null = null;
  const fetch: OpenAiFetch = async (input, init) => {
    const body = JSON.parse(String(init?.body ?? '{}')) as Record<string, unknown>;
    last = { bodyKeys: Object.keys(body).sort(), serviceTier: null };
    const res = await inner(input, init);
    try {
      const json = (await res.clone().json()) as { service_tier?: unknown };
      if (typeof json.service_tier === 'string') last.serviceTier = json.service_tier;
    } catch {
      /* non-JSON error body */
    }
    return res;
  };
  return { fetch, take: () => ((l) => ((last = null), l))(last) };
}

export function validated(attempt: Phase4c2Attempt) {
  return validateAiBody({
    operation: 'dream_analysis',
    payload: attempt.payload,
    model: attempt.clientModelHint,
  }) as Extract<ValidatedRequest, { operation: 'dream_analysis' }>;
}

export async function runPhase4c2(options: {
  attempts: Phase4c2Attempt[];
  config: AppConfig;
  fetch: OpenAiFetch;
  onRecord?: (record: Phase4c2Record, callsSoFar: number) => void;
}): Promise<{ records: Phase4c2Record[]; calls: number }> {
  const wire = observeFetch(options.fetch);
  const budget = budgetFetch(wire.fetch, PHASE4C2_MAX_CALLS);
  const transport = new OpenAiTransport(options.config, budget.fetch);
  const records: Phase4c2Record[] = [];
  for (const attempt of options.attempts) {
    if (budget.calls() >= PHASE4C2_MAX_CALLS) throw new Phase4cBudgetExceeded(`hard cap ${PHASE4C2_MAX_CALLS} reached`);
    const request = validated(attempt);
    const language = request.language as AppLanguage;
    const before = budget.calls();
    let passed = false;
    let error: unknown = null;
    try {
      await runDreamCandidate(transport, candidateOf(attempt.candidate), { payload: request.payload, language });
      passed = true;
    } catch (e) {
      if (e instanceof Phase4cBudgetExceeded) throw e;
      error = e;
    }
    const calls = budget.calls() - before;
    if (calls > 1) throw new Error(`${attempt.attemptId}: ${calls} provider calls in one attempt`);
    if (calls === 0) throw new Error(`${attempt.attemptId}: no provider call (input gate refused)`);
    const capture = budget.take()!;
    const raw = capture.rawText;
    records.push(
      buildRecord({
        attempt,
        payload: request.payload,
        memorySummarySent: memorySent(request.payload),
        writerRevision: PHASE4C2_WRITER_REVISION,
        capture,
        wire: wire.take(),
        stages: raw === null ? null : classifyPhase4c2(raw, request.payload, language),
        passed,
        errorCode: error instanceof ProxyError ? error.code : error ? 'unexpected' : null,
        providerErrorMessage:
          error instanceof ProxyError && typeof error.details?.providerMessage === 'string'
            ? error.details.providerMessage
            : null,
      }),
    );
    options.onRecord?.(records[records.length - 1], budget.calls());
  }
  return { records, calls: budget.calls() };
}

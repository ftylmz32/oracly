/**
 * Dream Phase 4C.2 — builds one attempt's evidence record: parameters from
 * the serialized request, HTTP class, usage/cost, the raw provider text and
 * the 4C.1 stage verdicts.
 */
import type { ProviderCapture } from '../dream-phase4c/budget-fetch.js';
import { candidate as candidateOf, estimateCostUsd } from './candidates.js';
import type { Phase4c2Attempt } from './matrix.js';
import { PENDING_REVIEW, type BackendFinal, type Phase4c2Record, type WireFacts } from './record-type.js';
import type { Phase4c2Stages } from './stages.js';

export { PENDING_REVIEW, type BackendFinal, type Phase4c2Record, type WireFacts } from './record-type.js';

type Usage = {
  prompt_tokens?: number;
  completion_tokens?: number;
  prompt_tokens_details?: { cached_tokens?: number; cache_write_tokens?: number } | null;
  completion_tokens_details?: { reasoning_tokens?: number } | null;
};

export function httpClass(status: number | null, networkError: string | null): string {
  if (status === null) return networkError === 'AbortError' ? 'timeout' : 'network';
  if (status === 408) return 'timeout';
  if (status >= 500) return '5xx';
  return String(status);
}

const n = (v: unknown) => (typeof v === 'number' ? v : null);

export function buildRecord(x: {
  attempt: Phase4c2Attempt;
  payload: Record<string, unknown>;
  memorySummarySent: string | null;
  writerRevision: string;
  capture: ProviderCapture;
  wire: WireFacts | null;
  stages: Phase4c2Stages | null;
  passed: boolean;
  errorCode: string | null;
  providerErrorMessage: string | null;
}): Phase4c2Record {
  const { payload: _p, candidate, ...meta } = x.attempt;
  const c = candidateOf(candidate);
  const { capture, stages } = x;
  const keys = x.wire?.bodyKeys ?? [];
  const ok = capture.status === 200;
  const empty = ok && capture.rawText === null;
  const backendFinal: BackendFinal = x.passed
    ? 'PASS'
    : ok
      ? 'REJECT'
      : capture.status === 400
        ? 'PARAMETER_ERROR'
        : 'TRANSPORT_ERROR';
  const usage = (capture.usage ?? null) as Usage | null;
  const serviceTier = x.wire?.serviceTier ?? null;
  const cost = ok ? estimateCostUsd(c, usage, serviceTier) : { usd: null, reason: 'no_successful_response' };
  return {
    ...meta,
    candidateModel: candidate,
    requestedModel: c.model,
    resolvedModel: capture.providerModel,
    endpoint: capture.endpoint,
    writerRevision: x.writerRevision,
    parameters: {
      reasoningEffort: capture.request.reasoningEffort,
      temperaturePresent: keys.includes('temperature'),
      temperature: capture.request.temperature,
      topPPresent: keys.includes('top_p'),
      logprobsPresent: keys.includes('logprobs'),
      topLogprobsPresent: keys.includes('top_logprobs'),
      responseFormat: capture.request.responseFormat,
      bodyKeys: keys,
    },
    providerCallOccurred: true,
    latencyMs: capture.latencyMs,
    httpStatus: capture.status,
    httpClass: httpClass(capture.status, capture.networkError),
    finishReason: capture.finishReason,
    serviceTier,
    usage: {
      inputTokens: n(usage?.prompt_tokens),
      outputTokens: n(usage?.completion_tokens),
      reasoningTokens: n(usage?.completion_tokens_details?.reasoning_tokens),
      cachedTokens: n(usage?.prompt_tokens_details?.cached_tokens),
      cacheWriteTokens: n(usage?.prompt_tokens_details?.cache_write_tokens),
      raw: (capture.usage as Record<string, unknown> | null) ?? null,
    },
    estimatedCostUsd: cost.usd,
    costNullReason: cost.reason,
    narrative: String(x.payload.narrative),
    symbolsSent: x.payload.symbols ?? [],
    emotionsSent: x.payload.emotions ?? [],
    memorySummarySent: x.memorySummarySent,
    history: x.payload.history ?? null,
    rawProviderText: capture.rawText,
    parseSuccess: stages?.parseSuccess ?? false,
    parsed: stages?.parsed ?? null,
    rawSymbols: stages?.rawSymbols ?? [],
    filteredSymbols: stages?.filteredSymbols ?? [],
    outputSafety: stages?.outputSafety ?? 'NOT_REACHED',
    symbolFilter: stages?.symbols ?? 'NOT_REACHED',
    phase2: stages?.phase2 ?? 'NOT_REACHED',
    phase4A: stages?.phase4A ?? 'NOT_REACHED',
    phase4B: stages?.phase4B ?? 'NOT_REACHED',
    firstFailure: empty ? 'empty_provider_content' : (stages?.firstFailure ?? null),
    failureStage: empty ? 'provider_content' : (stages?.failureStage ?? null),
    diagnostic: stages?.diagnostic ?? null,
    backendFinal,
    errorCode: x.errorCode,
    providerErrorMessage: x.providerErrorMessage,
    productionAgreement: stages ? stages.final === (x.passed ? 'PASS' : 'REJECT') : !x.passed,
    clientResult: backendFinal === 'PASS' ? 'PENDING_CLIENT_REPLAY' : 'NOT_DELIVERED',
    clientFailureReason: null,
    inventedConcreteSceneContent: PENDING_REVIEW,
    inventedConcreteSceneItems: [],
  };
}
